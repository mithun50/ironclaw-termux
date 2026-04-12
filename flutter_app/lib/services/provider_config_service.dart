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
  /// Path to ironclaw.yaml — saved in /root (proot working directory) so that
  /// `ironclaw run` finds it automatically.
  static const _configPath = 'root/ironclaw.yaml';
  static const _envFilePath = 'root/.ironclaw/.env';

  /// Escape a string for use as a single-quoted shell argument.
  static String _shellEscape(String s) {
    return s.replaceAll("'", "'\\''");
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

    try {
      final yaml = await NativeBridge.readRootfsFile(_configPath);
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
        if (RegExp('^${provider.envVarName}=.+', multiLine: true).hasMatch(envContent)) {
          providers[provider.id] = {'configured': true};
        }
      }
    } catch (_) {}

    return {
      'activeProvider': activeProvider,
      'activeModel': activeModel,
      'providers': providers,
    };
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
else
  cat > "\\\$CONFIG" <<'YAML'
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
YAML
fi
""";
    try {
      await NativeBridge.runInProot('bash -c \'${_shellEscape(script)}\'', timeout: 15);
    } catch (_) {
      // Fallback: write .env directly
      try {
        final existing = await NativeBridge.readRootfsFile(_envFilePath) ?? '';
        final lines = existing.split('\n').where((l) => !l.startsWith('$envVar=')).toList();
        lines.add('$envVar=$apiKey');
        await NativeBridge.writeRootfsFile(_envFilePath, lines.join('\n'));
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
  }
}
