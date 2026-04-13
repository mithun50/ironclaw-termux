import 'dart:convert';

import '../models/ai_provider.dart';
import 'native_bridge.dart';

/// Reads and writes AI provider configuration for IronClaw.
///
/// IronClaw reads API keys exclusively from environment variables
/// (e.g. ANTHROPIC_API_KEY). This service manages:
///   - Writing keys to `/root/.ironclaw/.env` (sourced from .bashrc)
///   - Writing `ironclaw.yaml` to `/root/` with default_provider/default_model
/// Keys never leave the device and are stored only inside the proot rootfs.
class ProviderConfigService {
  /// Path to ironclaw.yaml — saved in /root (the proot working directory) so
  /// `ironclaw --config /root/ironclaw.yaml run ...` uses it directly.
  static const configPath = 'root/ironclaw.yaml';
  static const legacyConfigPath = 'root/.ironclaw/ironclaw.yaml';
  static const _envFilePath = 'root/.ironclaw/.env';
  static const _providerMetadataPath = 'root/.ironclaw/providers.json';

  /// Escape a string for use as a single-quoted shell argument.
  static String _shellEscape(String s) {
    return s.replaceAll("'", "'\\''");
  }

  static String _defaultConfigYaml({
    required String providerId,
    required String model,
  }) {
    return '''
agent:
  default_provider: "$providerId"
  default_model: "$model"
  max_turns: 100
  tool_timeout_secs: 30

memory:
  backend: "encrypted_sqlite"

ui:
  enabled: true
  bind_address: "127.0.0.1"
  port: 3000
  theme: "dark"

permissions:
  system:
    allow_shell: false
    require_approval_for_high_risk: true

audit:
  enabled: true
  path: "~/.ironclaw/audit.log"
''';
  }

  static Future<Map<String, dynamic>> _readProviderMetadata() async {
    try {
      final raw = await NativeBridge.readRootfsFile(_providerMetadataPath);
      if (raw == null || raw.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _writeProviderMetadata(Map<String, dynamic> data) async {
    await NativeBridge.writeRootfsFile(
      _providerMetadataPath,
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  static Future<Map<String, String>> readStoredModels() async {
    final metadata = await _readProviderMetadata();
    final models = <String, String>{};
    for (final entry in metadata.entries) {
      final value = entry.value;
      if (value is Map && value['model'] is String) {
        final model = (value['model'] as String).trim();
        if (model.isNotEmpty) {
          models[entry.key] = model;
        }
      }
    }
    return models;
  }

  static Future<void> _saveStoredModel({
    required String providerId,
    required String model,
  }) async {
    final metadata = await _readProviderMetadata();
    final entry = (metadata[providerId] as Map?)?.cast<String, dynamic>() ?? {};
    entry['model'] = model;
    metadata[providerId] = entry;
    await _writeProviderMetadata(metadata);
  }

  static String _upsertConfigYaml(
    String? existingYaml, {
    required String providerId,
    required String model,
  }) {
    if (existingYaml == null || existingYaml.trim().isEmpty) {
      return _defaultConfigYaml(providerId: providerId, model: model);
    }

    var yaml = existingYaml;
    if (!RegExp(r'(?m)^agent:\s*$').hasMatch(yaml)) {
      return 'agent:\n'
          '  default_provider: "$providerId"\n'
          '  default_model: "$model"\n\n'
          '$yaml';
    }

    if (RegExp(r'(?m)^\s*default_provider:').hasMatch(yaml)) {
      yaml = yaml.replaceFirst(
        RegExp(r'(?m)^(\s*)default_provider:\s*.*$'),
        r'$1default_provider: "' + providerId + '"',
      );
    } else {
      yaml = yaml.replaceFirst(
        RegExp(r'(?m)^agent:\s*$'),
        'agent:\n  default_provider: "$providerId"',
      );
    }

    if (RegExp(r'(?m)^\s*default_model:').hasMatch(yaml)) {
      yaml = yaml.replaceFirst(
        RegExp(r'(?m)^(\s*)default_model:\s*.*$'),
        r'$1default_model: "' + model + '"',
      );
    } else if (RegExp(r'(?m)^\s*default_provider:.*$').hasMatch(yaml)) {
      yaml = yaml.replaceFirst(
        RegExp(r'(?m)^(\s*default_provider:.*)$'),
        r'$1\n  default_model: "' + model + '"',
      );
    } else {
      yaml = yaml.replaceFirst(
        RegExp(r'(?m)^agent:\s*$'),
        'agent:\n  default_model: "$model"',
      );
    }

    return yaml;
  }

  /// Read the current active provider/model and which providers have keys.
  ///
  /// Returns:
  ///   - `activeProvider`: the `default_provider` value from ironclaw.yaml
  ///   - `activeModel`: the `default_model` value from ironclaw.yaml
  ///   - `providers`: map of provider id → `{'configured': true}` for each
  ///     provider whose env var is present in the .env file
  static Future<Map<String, dynamic>> readConfig() async {
    String? activeProvider, activeModel;
    final Map<String, dynamic> providers = {};
    final storedModels = await readStoredModels();

    try {
      final yaml = await readConfigYaml();
      if (yaml != null && yaml.isNotEmpty) {
        String? extract(String key) {
          final match = RegExp(r'^\s*' + key + r':\s*["\x27]?([^"' + "'" + r'\n]+)["\x27]?',
              multiLine: true).firstMatch(yaml);
          return match?.group(1)?.trim();
        }
        activeProvider = extract('default_provider');
        activeModel = extract('default_model');
      }
    } catch (_) {}

    try {
      final envContent = await NativeBridge.readRootfsFile(_envFilePath) ?? '';
      for (final provider in AiProvider.all) {
        final hasKey = RegExp('^${provider.envVarName}=.+', multiLine: true).hasMatch(envContent);
        final isConfigured = provider.requiresApiKey
            ? hasKey
            : storedModels.containsKey(provider.id) || activeProvider == provider.ironclawId;
        if (isConfigured) {
          providers[provider.id] = {
            'configured': true,
            'model': storedModels[provider.id] ??
                (activeProvider == provider.ironclawId ? activeModel : null),
          };
        }
      }
    } catch (_) {}

    return {
      'activeProvider': activeProvider,
      'activeModel': activeModel,
      'providers': providers,
    };
  }

  static Future<String?> readConfigYaml() async {
    final primary = await NativeBridge.readRootfsFile(configPath);
    if (primary != null && primary.trim().isNotEmpty) {
      return primary;
    }
    return NativeBridge.readRootfsFile(legacyConfigPath);
  }

  static Future<void> writeConfigYaml(String content) async {
    await NativeBridge.writeRootfsFile(configPath, content);
    await NativeBridge.writeRootfsFile(legacyConfigPath, content);
  }

  static Future<void> setActiveProviderConfig({
    required AiProvider provider,
    required String model,
  }) async {
    final current = await readConfigYaml();
    final updated = _upsertConfigYaml(
      current,
      providerId: provider.ironclawId,
      model: model,
    );
    await writeConfigYaml(updated);
    await _saveStoredModel(providerId: provider.id, model: model);
  }

  /// Save the provider API key as an environment variable and update
  /// ironclaw.yaml with default_provider and default_model.
  static Future<void> saveProviderConfig({
    required AiProvider provider,
    required String apiKey,
    required String model,
  }) async {
    final envVar = provider.envVarName;
    final providerId = provider.ironclawId;

    final script = """
#!/bin/bash
set -e
mkdir -p /root/.ironclaw

# Write API key to .env
ENV_FILE="/root/.ironclaw/.env"
if [ -f "\\\$ENV_FILE" ]; then
  sed -i '/^${envVar}=/d' "\\\$ENV_FILE"
fi
echo '${envVar}=${_shellEscape(apiKey)}' >> "\\\$ENV_FILE"

# Source .env on login
BASHRC="/root/.bashrc"
if ! grep -q '.ironclaw/.env' "\\\$BASHRC" 2>/dev/null; then
  echo '[ -f /root/.ironclaw/.env ] && . /root/.ironclaw/.env' >> "\\\$BASHRC"
fi

# Write ironclaw.yaml to /root (CWD when ironclaw runs)
CONFIG="/root/ironclaw.yaml"
if [ -f "\\\$CONFIG" ]; then
  if ! grep -q '^agent:' "\\\$CONFIG"; then
    {
      printf 'agent:\\n  default_provider: "$providerId"\\n  default_model: "$model"\\n'
      cat "\\\$CONFIG"
    } > "\\\$CONFIG.tmp"
    mv "\\\$CONFIG.tmp" "\\\$CONFIG"
  else
    if grep -q 'default_provider:' "\\\$CONFIG"; then
      sed -i 's|^  default_provider:.*|  default_provider: "$providerId"|' "\\\$CONFIG"
    else
      sed -i '/^agent:/a\\  default_provider: "$providerId"' "\\\$CONFIG"
    fi
    if grep -q 'default_model:' "\\\$CONFIG"; then
      sed -i 's|^  default_model:.*|  default_model: "$model"|' "\\\$CONFIG"
    else
      sed -i '/^  default_provider:/a\\  default_model: "$model"' "\\\$CONFIG"
    fi
  fi
else
  cat > "\\\$CONFIG" <<'YAML'
${_defaultConfigYaml(providerId: providerId, model: model)}
YAML
fi

cp "\\\$CONFIG" /root/.ironclaw/ironclaw.yaml
""";
    try {
      await NativeBridge.runInProot('bash -c \'${_shellEscape(script)}\'', timeout: 15);
      await _saveStoredModel(providerId: provider.id, model: model);
    } catch (_) {
      // Fallback: write .env directly
      try {
        final existing = await NativeBridge.readRootfsFile(_envFilePath) ?? '';
        final lines = existing.split('\n').where((l) => !l.startsWith('$envVar=')).toList();
        lines.add('$envVar=$apiKey');
        await NativeBridge.writeRootfsFile(_envFilePath, lines.join('\n'));
        await setActiveProviderConfig(provider: provider, model: model);
      } catch (_) {}
    }
  }

  /// Remove a provider''s API key from the .env file.
  static Future<void> removeProviderConfig({
    required AiProvider provider,
  }) async {
    final envVar = provider.envVarName;
    try {
      await NativeBridge.runInProot(
        "bash -c \"sed -i '/^${envVar}=/d' /root/.ironclaw/.env 2>/dev/null || true\"",
        timeout: 10,
      );
    } catch (_) {}
    try {
      final metadata = await _readProviderMetadata();
      metadata.remove(provider.id);
      await _writeProviderMetadata(metadata);
    } catch (_) {}
  }
}
