import '../models/ai_provider.dart';
import 'native_bridge.dart';

/// Reads and writes AI provider configuration for IronClaw.
///
/// IronClaw uses:
///   - Environment variables for API keys (e.g. ANTHROPIC_API_KEY)
///   - `ironclaw.yaml` in the working directory (or created by `ironclaw onboard`)
///     for default_provider / default_model settings.
/// The .env file is stored at /root/.ironclaw/.env and sourced from /root/.bashrc.
class ProviderConfigService {
  /// Path to ironclaw.yaml — saved in /root (proot working directory) so that
  /// `ironclaw run` finds it automatically, matching what `ironclaw onboard` produces.
  static const _configPath = 'root/ironclaw.yaml';
  static const _envFilePath = 'root/.ironclaw/.env';

  /// Escape a string for use as a single-quoted shell argument.
  static String _shellEscape(String s) {
    return s.replaceAll("'", "'\\''");
  }

  /// Read the current active provider/model from ironclaw.yaml.
  static Future<Map<String, dynamic>> readConfig() async {
    try {
      final content = await NativeBridge.readRootfsFile(_configPath);
      if (content == null || content.isEmpty) {
        return {'activeProvider': null, 'activeModel': null};
      }
      String? extractYaml(String key) {
        final match = RegExp(r'^\s*' + key + r':\s*["\x27]?([^"' + "'" + r'\n]+)["\x27]?',
            multiLine: true).firstMatch(content);
        return match?.group(1)?.trim();
      }
      return {
        'activeProvider': extractYaml('default_provider'),
        'activeModel': extractYaml('default_model'),
      };
    } catch (_) {
      return {'activeProvider': null, 'activeModel': null};
    }
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

ui:
  enabled: false
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
