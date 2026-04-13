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

  static Future<Map<String, String>> _readEnvMap() async {
    final raw = await NativeBridge.readRootfsFile(_envFilePath) ?? '';
    final values = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      values[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
    }
    return values;
  }

  static Future<void> _writeEnvMap(Map<String, String> values) async {
    final lines = values.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .toList()
      ..sort();
    final content = lines.isEmpty ? '' : '${lines.join('\n')}\n';
    await NativeBridge.writeRootfsFile(_envFilePath, content);
  }

  static Future<void> _ensureBashrcEnvSource() async {
    const sourceLine = '[ -f /root/.ironclaw/.env ] && . /root/.ironclaw/.env';
    final existing = await NativeBridge.readRootfsFile('root/.bashrc') ?? '';
    if (!existing.contains(sourceLine)) {
      final suffix = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
      await NativeBridge.writeRootfsFile(
        'root/.bashrc',
        '$existing$suffix$sourceLine\n',
      );
    }
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

  static String _clearActiveProviderConfig(String? existingYaml) {
    if (existingYaml == null || existingYaml.trim().isEmpty) {
      return '';
    }

    var yaml = existingYaml.replaceAll(
      RegExp(r'(?m)^\s*default_provider:\s*.*\n?'),
      '',
    );
    yaml = yaml.replaceAll(
      RegExp(r'(?m)^\s*default_model:\s*.*\n?'),
      '',
    );
    return yaml.replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight();
  }

  /// Save the provider API key as an environment variable and update
  /// ironclaw.yaml with default_provider and default_model.
  static Future<void> saveProviderConfig({
    required AiProvider provider,
    required String apiKey,
    required String model,
  }) async {
    final envVar = provider.envVarName;
    final envValues = await _readEnvMap();
    if (provider.requiresApiKey) {
      final trimmedKey = apiKey.trim();
      if (trimmedKey.isNotEmpty) {
        envValues[envVar] = trimmedKey;
      } else if ((envValues[envVar] ?? '').trim().isEmpty) {
        throw StateError('${provider.name} API key is required');
      }
    } else {
      envValues.remove(envVar);
    }
    await _writeEnvMap(envValues);
    await _ensureBashrcEnvSource();
    await setActiveProviderConfig(provider: provider, model: model);
  }

  /// Remove a provider''s API key from the .env file.
  static Future<void> removeProviderConfig({
    required AiProvider provider,
  }) async {
    final envVar = provider.envVarName;
    final envValues = await _readEnvMap();
    envValues.remove(envVar);
    await _writeEnvMap(envValues);

    final metadata = await _readProviderMetadata();
    metadata.remove(provider.id);
    await _writeProviderMetadata(metadata);

    final current = await readConfig();
    final wasActive = current['activeProvider'] == provider.ironclawId;
    if (!wasActive) {
      return;
    }

    final remainingModels = await readStoredModels();
    AiProvider? replacement;
    for (final candidate in AiProvider.all) {
      final hasKey = (envValues[candidate.envVarName] ?? '').trim().isNotEmpty;
      final isConfigured = candidate.requiresApiKey
          ? hasKey
          : remainingModels.containsKey(candidate.id);
      if (isConfigured) {
        replacement = candidate;
        break;
      }
    }

    if (replacement != null) {
      await setActiveProviderConfig(
        provider: replacement,
        model: remainingModels[replacement.id] ?? replacement.defaultModels.first,
      );
      return;
    }

    final cleared = _clearActiveProviderConfig(await readConfigYaml());
    await writeConfigYaml(cleared);
  }
}
