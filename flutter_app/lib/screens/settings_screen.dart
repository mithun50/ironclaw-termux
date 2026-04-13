import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../constants.dart';
import '../providers/node_provider.dart';
import '../services/native_bridge.dart';
import '../services/preferences_service.dart';
import '../services/provider_config_service.dart';
import '../services/update_service.dart';
import 'node_screen.dart';
import 'setup_wizard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  bool _autoStart = false;
  bool _nodeEnabled = false;
  bool _batteryOptimized = true;
  String _arch = '';
  String _prootPath = '';
  Map<String, dynamic> _status = {};
  bool _loading = true;
  bool _goInstalled = false;
  bool _brewInstalled = false;
  bool _sshInstalled = false;
  bool _storageGranted = false;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _prefs.init();
    _autoStart = _prefs.autoStartGateway;
    _nodeEnabled = _prefs.nodeEnabled;

    try {
      final arch = await NativeBridge.getArch();
      final prootPath = await NativeBridge.getProotPath();
      final status = await NativeBridge.getBootstrapStatus();
      final batteryOptimized = await NativeBridge.isBatteryOptimized();

      final storageGranted = await NativeBridge.hasStoragePermission();

      // Check optional package statuses
      final filesDir = await NativeBridge.getFilesDir();
      final rootfs = '$filesDir/rootfs/ubuntu';
      final goInstalled = File('$rootfs/usr/bin/go').existsSync();
      final brewInstalled =
          File('$rootfs/home/linuxbrew/.linuxbrew/bin/brew').existsSync();
      final sshInstalled = File('$rootfs/usr/bin/ssh').existsSync();

      setState(() {
        _batteryOptimized = batteryOptimized;
        _storageGranted = storageGranted;
        _arch = arch;
        _prootPath = prootPath;
        _status = status;
        _goInstalled = goInstalled;
        _brewInstalled = brewInstalled;
        _sshInstalled = sshInstalled;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(theme, 'GENERAL'),
                SwitchListTile(
                  title: const Text('Auto-start gateway'),
                  subtitle: const Text('Start the gateway when the app opens'),
                  value: _autoStart,
                  onChanged: (value) {
                    setState(() => _autoStart = value);
                    _prefs.autoStartGateway = value;
                  },
                ),
                ListTile(
                  title: const Text('Battery Optimization'),
                  subtitle: Text(_batteryOptimized
                      ? 'Optimized (may kill background sessions)'
                      : 'Unrestricted (recommended)'),
                  leading: const Icon(Icons.battery_alert),
                  trailing: _batteryOptimized
                      ? const Icon(Icons.warning, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestBatteryOptimization();
                    // Refresh status after returning from settings
                    final optimized = await NativeBridge.isBatteryOptimized();
                    setState(() => _batteryOptimized = optimized);
                  },
                ),
                ListTile(
                  title: const Text('Setup Storage'),
                  subtitle: Text(_storageGranted
                      ? 'Granted — proot can access /sdcard. Revoke if not needed.'
                      : 'Not granted (recommended) — tap to grant only if needed'),
                  leading: const Icon(Icons.sd_storage),
                  trailing: _storageGranted
                      ? const Icon(Icons.warning_amber, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestStoragePermission();
                    // Refresh after returning from permission screen
                    final granted = await NativeBridge.hasStoragePermission();
                    setState(() => _storageGranted = granted);
                  },
                ),
                const Divider(),
                _sectionHeader(theme, 'NODE'),
                SwitchListTile(
                  title: const Text('Enable Node'),
                  subtitle: const Text('Provide device capabilities to the gateway'),
                  value: _nodeEnabled,
                  onChanged: (value) {
                    setState(() => _nodeEnabled = value);
                    _prefs.nodeEnabled = value;
                    final nodeProvider = context.read<NodeProvider>();
                    if (value) {
                      nodeProvider.enable();
                    } else {
                      nodeProvider.disable();
                    }
                  },
                ),
                ListTile(
                  title: const Text('Node Configuration'),
                  subtitle: const Text('Connection, pairing, and capabilities'),
                  leading: const Icon(Icons.devices),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NodeScreen()),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'SYSTEM INFO'),
                ListTile(
                  title: const Text('Architecture'),
                  subtitle: Text(_arch),
                  leading: const Icon(Icons.memory),
                ),
                ListTile(
                  title: const Text('PRoot path'),
                  subtitle: Text(_prootPath),
                  leading: const Icon(Icons.folder),
                ),
                ListTile(
                  title: const Text('Rootfs'),
                  subtitle: Text(_status['rootfsExists'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.storage),
                ),
                ListTile(
                  title: const Text('Node.js'),
                  subtitle: Text(_status['nodeInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.code),
                ),
                ListTile(
                  title: const Text('IronClaw'),
                  subtitle: Text(_status['ironclawInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.cloud),
                ),
                ListTile(
                  title: const Text('Go (Golang)'),
                  subtitle: Text(_goInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.integration_instructions),
                ),
                ListTile(
                  title: const Text('Homebrew'),
                  subtitle: Text(_brewInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.science),
                ),
                ListTile(
                  title: const Text('OpenSSH'),
                  subtitle: Text(_sshInstalled
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.vpn_key),
                ),
                const Divider(),
                _sectionHeader(theme, 'MAINTENANCE'),
                ListTile(
                  title: const Text('Export Snapshot'),
                  subtitle: const Text('Backup config to Downloads'),
                  leading: const Icon(Icons.upload_file),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportSnapshot,
                ),
                ListTile(
                  title: const Text('Import Snapshot'),
                  subtitle: const Text('Restore config from backup'),
                  leading: const Icon(Icons.download),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importSnapshot,
                ),
                ListTile(
                  title: const Text('Re-run setup'),
                  subtitle: const Text('Reinstall or repair the environment'),
                  leading: const Icon(Icons.build),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SetupWizardScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'ADVANCED CONFIG'),
                ListTile(
                  title: const Text('Advanced Config'),
                  subtitle: const Text('System prompt, costs, DLP, audit, security'),
                  leading: const Icon(Icons.tune),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _AdvancedConfigScreen()),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'ABOUT'),
                const ListTile(
                  title: Text('IronClaw'),
                  subtitle: Text(
                    'AI Agent for Android\nVersion ${AppConstants.version}',
                  ),
                  leading: Icon(Icons.info_outline),
                  isThreeLine: true,
                ),
                ListTile(
                  title: const Text('Check for Updates'),
                  subtitle: const Text('Check GitHub for a newer release'),
                  leading: _checkingUpdate
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  onTap: _checkingUpdate ? null : _checkForUpdates,
                ),
                const ListTile(
                  title: Text('Developer'),
                  subtitle: Text(AppConstants.authorName),
                  leading: Icon(Icons.person),
                ),
                ListTile(
                  title: const Text('GitHub'),
                  subtitle: const Text('mithun50/ironclaw-termux'),
                  leading: const Icon(Icons.code),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.githubUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Contact'),
                  subtitle: const Text(AppConstants.authorEmail),
                  leading: const Icon(Icons.email),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:${AppConstants.authorEmail}'),
                  ),
                ),
                const ListTile(
                  title: Text('License'),
                  subtitle: Text(AppConstants.license),
                  leading: Icon(Icons.description),
                ),
                const Divider(),
                _sectionHeader(theme, AppConstants.orgName.toUpperCase()),
                ListTile(
                  title: const Text('Instagram'),
                  subtitle: const Text('@nexgenxplorer_nxg'),
                  leading: const Icon(Icons.camera_alt),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.instagramUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('YouTube'),
                  subtitle: const Text('@nexgenxplorer'),
                  leading: const Icon(Icons.play_circle_fill),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.youtubeUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Play Store'),
                  subtitle: const Text('NextGenX Apps'),
                  leading: const Icon(Icons.shop),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.playStoreUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: const Text(AppConstants.orgEmail),
                  leading: const Icon(Icons.email_outlined),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:${AppConstants.orgEmail}'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<String> _getSnapshotPath() async {
    final hasPermission = await NativeBridge.hasStoragePermission();
    if (hasPermission) {
      final sdcard = await NativeBridge.getExternalStoragePath();
      final downloadDir = Directory('$sdcard/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return '$sdcard/Download/ironclaw-snapshot.json';
    }
    // Fallback to app-private directory
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/ironclaw-snapshot.json';
  }

  Future<void> _exportSnapshot() async {
    try {
      final ironclawYaml = await ProviderConfigService.readConfigYaml();
      final snapshot = {
        'version': AppConstants.version,
        'timestamp': DateTime.now().toIso8601String(),
        'ironclawConfig': ironclawYaml,
        'dashboardUrl': _prefs.dashboardUrl,
        'autoStart': _prefs.autoStartGateway,
        'nodeEnabled': _prefs.nodeEnabled,
        'nodeDeviceToken': _prefs.nodeDeviceToken,
        'nodeGatewayHost': _prefs.nodeGatewayHost,
        'nodeGatewayPort': _prefs.nodeGatewayPort,
        'nodeGatewayToken': _prefs.nodeGatewayToken,
      };

      final path = await _getSnapshotPath();
      final file = File(path);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importSnapshot() async {
    try {
      final path = await _getSnapshotPath();
      final file = File(path);

      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No snapshot found at $path')),
        );
        return;
      }

      final content = await file.readAsString();
      final snapshot = jsonDecode(content) as Map<String, dynamic>;

      // Restore ironclaw.yaml into rootfs
      final ironclawConfig = snapshot['ironclawConfig'] as String?;
      if (ironclawConfig != null) {
        await ProviderConfigService.writeConfigYaml(ironclawConfig);
      }

      // Restore preferences
      if (snapshot['dashboardUrl'] != null) {
        _prefs.dashboardUrl = snapshot['dashboardUrl'] as String;
      }
      if (snapshot['autoStart'] != null) {
        _prefs.autoStartGateway = snapshot['autoStart'] as bool;
      }
      if (snapshot['nodeEnabled'] != null) {
        _prefs.nodeEnabled = snapshot['nodeEnabled'] as bool;
      }
      if (snapshot['nodeDeviceToken'] != null) {
        _prefs.nodeDeviceToken = snapshot['nodeDeviceToken'] as String;
      }
      if (snapshot['nodeGatewayHost'] != null) {
        _prefs.nodeGatewayHost = snapshot['nodeGatewayHost'] as String;
      }
      if (snapshot['nodeGatewayPort'] != null) {
        _prefs.nodeGatewayPort = snapshot['nodeGatewayPort'] as int;
      }
      if (snapshot['nodeGatewayToken'] != null) {
        _prefs.nodeGatewayToken = snapshot['nodeGatewayToken'] as String;
      }

      // Refresh UI
      await _loadSettings();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot restored successfully. Restart the gateway to apply.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    try {
      final result = await UpdateService.check();
      if (!mounted) return;
      if (result.available) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update Available'),
            content: Text(
              'A new version is available.\n\n'
              'Current: ${AppConstants.version}\n'
              'Latest: ${result.latest}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  launchUrl(
                    Uri.parse(result.url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('Download'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on the latest version")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates')),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Advanced Config Screen ───────────────────────────────────────────────────

class _AdvancedConfigScreen extends StatefulWidget {
  const _AdvancedConfigScreen();

  @override
  State<_AdvancedConfigScreen> createState() => _AdvancedConfigScreenState();
}

class _AdvancedConfigScreenState extends State<_AdvancedConfigScreen> {
  bool _loading = true;
  bool _saving = false;
  String _yaml = '';

  final _systemPromptCtrl = TextEditingController();
  final _maxTurnsCtrl = TextEditingController(text: '100');
  final _maxDailyCostCtrl = TextEditingController(text: '0');
  final _sessionTtlCtrl = TextEditingController(text: '60');

  bool _dlpEnabled = true;
  String _dlpDefaultAction = 'redact';
  bool _sessionAuthEnabled = false;
  bool _auditEnabled = true;
  bool _guardianBlockPipes = false;
  bool _guardianBlockRedirects = false;

  static const _dlpActions = ['redact', 'block', 'warn'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _systemPromptCtrl.dispose();
    _maxTurnsCtrl.dispose();
    _maxDailyCostCtrl.dispose();
    _sessionTtlCtrl.dispose();
    super.dispose();
  }

  String? _extract(String yaml, String key) {
    final m = RegExp(
      r'^\s*' + key.replaceAll('.', r'\.') + r':\s*["\x27]?([^"' + "'" + r'\s][^"' + "'" + r'\n]*)["\x27]?',
      multiLine: true,
    ).firstMatch(yaml);
    return m?.group(1)?.trim();
  }

  String? _extractSystemPrompt(String yaml) {
    final m = RegExp(
      r'(?ms)^\s*system_prompt:\s*["\x27]?(.*?)["\x27]?\s*$',
      multiLine: true,
    ).firstMatch(yaml);
    return m?.group(1)?.trim();
  }

  Future<void> _loadConfig() async {
    try {
      final yaml = await ProviderConfigService.readConfigYaml() ?? '';
      setState(() {
        _yaml = yaml;

        _systemPromptCtrl.text = _extractSystemPrompt(yaml) ?? '';
        _maxTurnsCtrl.text = _extract(yaml, 'max_turns') ?? '100';

        final costCents = int.tryParse(_extract(yaml, 'max_daily_cost_cents') ?? '0') ?? 0;
        _maxDailyCostCtrl.text = (costCents / 100).toStringAsFixed(2);

        _dlpEnabled = (_extract(yaml, 'dlp.enabled') ?? 'true') == 'true';
        _dlpDefaultAction = _dlpActions.contains(_extract(yaml, 'default_action'))
            ? _extract(yaml, 'default_action')!
            : 'redact';
        _sessionAuthEnabled = (_extract(yaml, 'session_auth.enabled') ?? 'false') == 'true';

        final ttlSecs = int.tryParse(_extract(yaml, 'ttl_secs') ?? '3600') ?? 3600;
        _sessionTtlCtrl.text = (ttlSecs ~/ 60).toString();

        _auditEnabled = (_extract(yaml, 'audit.enabled') ?? 'true') == 'true';
        _guardianBlockPipes = (_extract(yaml, 'block_pipes') ?? 'false') == 'true';
        _guardianBlockRedirects = (_extract(yaml, 'block_redirects') ?? 'false') == 'true';

        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _upsert(String yaml, String key, String value) {
    final parts = key.split('.');
    final field = parts.last;
    final pattern = RegExp(r'(?m)^\s*' + field + r':\s*.*$');
    if (pattern.hasMatch(yaml)) {
      return yaml.replaceFirst(pattern, '  $field: $value');
    }
    if (parts.length > 1) {
      final section = parts.first;
      final sectionPattern = RegExp(r'(?m)^' + section + r':\s*$');
      if (sectionPattern.hasMatch(yaml)) {
        return yaml.replaceFirst(sectionPattern, '$section:\n  $field: $value');
      }
      return '$yaml\n$section:\n  $field: $value\n';
    }
    return '$yaml\n$field: $value\n';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var yaml = _yaml;

      final costDollars = double.tryParse(_maxDailyCostCtrl.text) ?? 0;
      final costCents = (costDollars * 100).round();
      final ttlMins = int.tryParse(_sessionTtlCtrl.text) ?? 60;
      final ttlSecs = ttlMins * 60;

      yaml = _upsert(yaml, 'agent.system_prompt', _systemPromptCtrl.text.trim());
      yaml = _upsert(yaml, 'agent.max_turns', _maxTurnsCtrl.text.trim());
      yaml = _upsert(yaml, 'agent.max_daily_cost_cents', '$costCents');
      yaml = _upsert(yaml, 'dlp.enabled', '$_dlpEnabled');
      yaml = _upsert(yaml, 'dlp.default_action', _dlpDefaultAction);
      yaml = _upsert(yaml, 'session_auth.enabled', '$_sessionAuthEnabled');
      yaml = _upsert(yaml, 'session_auth.ttl_secs', '$ttlSecs');
      yaml = _upsert(yaml, 'audit.enabled', '$_auditEnabled');
      yaml = _upsert(yaml, 'guardian.block_pipes', '$_guardianBlockPipes');
      yaml = _upsert(yaml, 'guardian.block_redirects', '$_guardianBlockRedirects');

      await ProviderConfigService.writeConfigYaml(yaml);
      _yaml = yaml;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetToDefaults() {
    setState(() {
      _systemPromptCtrl.text = '';
      _maxTurnsCtrl.text = '100';
      _maxDailyCostCtrl.text = '0.00';
      _dlpEnabled = true;
      _dlpDefaultAction = 'redact';
      _sessionAuthEnabled = false;
      _sessionTtlCtrl.text = '60';
      _auditEnabled = true;
      _guardianBlockPipes = false;
      _guardianBlockRedirects = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Config'),
        actions: [
          TextButton(
            onPressed: _loading || _saving ? null : _resetToDefaults,
            child: const Text('Reset'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _loading || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader(theme, 'AGENT'),
                const SizedBox(height: 8),
                TextField(
                  controller: _systemPromptCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'System prompt',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxTurnsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max turns',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxDailyCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Max daily cost (\$)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader(theme, 'DLP'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DLP enabled'),
                  value: _dlpEnabled,
                  onChanged: (v) => setState(() => _dlpEnabled = v),
                ),
                DropdownButtonFormField<String>(
                  value: _dlpDefaultAction,
                  decoration: const InputDecoration(
                    labelText: 'Default action',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _dlpActions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _dlpDefaultAction = v ?? 'redact'),
                ),
                const SizedBox(height: 16),
                _sectionHeader(theme, 'SESSION AUTH'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session auth enabled'),
                  value: _sessionAuthEnabled,
                  onChanged: (v) => setState(() => _sessionAuthEnabled = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sessionTtlCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Session TTL (minutes)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader(theme, 'AUDIT'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Audit enabled'),
                  value: _auditEnabled,
                  onChanged: (v) => setState(() => _auditEnabled = v),
                ),
                const SizedBox(height: 16),
                _sectionHeader(theme, 'GUARDIAN'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Block pipes'),
                  subtitle: const Text('Prevent piped command execution'),
                  value: _guardianBlockPipes,
                  onChanged: (v) => setState(() => _guardianBlockPipes = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Block redirects'),
                  subtitle: const Text('Prevent shell output redirection'),
                  value: _guardianBlockRedirects,
                  onChanged: (v) => setState(() => _guardianBlockRedirects = v),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
