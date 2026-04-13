import 'package:flutter/material.dart';
import '../app.dart';
import '../services/native_bridge.dart';

enum _CheckStatus { pending, pass, fail, warn }

class _CheckResult {
  final String id;
  final String description;
  _CheckStatus status;

  _CheckResult(this.id, this.description, {this.status = _CheckStatus.pending});
}

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  static const _staticChecks = [
    ('binary',      'ironclaw binary exists and is executable'),
    ('version',     'Installed version matches expected release'),
    ('config',      '~/.ironclaw/config.yaml or ./ironclaw.yaml present'),
    ('env_file',    '/root/.ironclaw/.env exists with at least one key'),
    ('api_key',     'Active provider has a valid API key configured'),
    ('provider',    'Active provider endpoint responds to a ping'),
    ('memory_db',   'AES-256-GCM encrypted SQLite memory.db writable'),
    ('sandbox',     'sandbox.backend = "native" (Docker n/a on Android)'),
    ('permissions', 'RBAC deny-first policy loaded'),
    ('skills_dir',  '/root/.ironclaw/skills/ exists'),
    ('skill_sigs',  'All installed skills have valid Ed25519 signatures'),
    ('audit_log',   'Audit log file is writable and not corrupted'),
    ('dlp',         'Data loss prevention patterns loaded'),
    ('ssrf',        'SSRF blocklist includes cloud metadata endpoints'),
    ('rate_limit',  'Token-bucket rate limiter initialised'),
    ('web_ui',      'Web UI can bind to port 3000'),
    ('session_auth','HMAC-SHA256 session token generation works'),
    ('ssl',         'SSL certificates installed (for HTTPS calls)'),
    ('proot',       'proot environment is functional'),
    ('rust_env',    'RUST_LOG and PATH include /root/.cargo/bin'),
  ];

  bool _loading = false;
  bool _setupRequired = false;
  String? _error;
  List<_CheckResult> _results = _staticChecks
      .map((c) => _CheckResult(c.$1, c.$2))
      .toList();

  int get _passCount => _results.where((r) => r.status == _CheckStatus.pass).length;
  int get _failCount => _results.where((r) => r.status == _CheckStatus.fail).length;
  int get _warnCount => _results.where((r) => r.status == _CheckStatus.warn).length;

  @override
  void initState() {
    super.initState();
    _runDoctor();
  }

  Future<void> _runDoctor() async {
    setState(() {
      _loading = true;
      _setupRequired = false;
      _error = null;
      _results = _staticChecks.map((c) => _CheckResult(c.$1, c.$2)).toList();
    });

    try {
      final output = await NativeBridge.runInProot('ironclaw doctor');

      if (output.contains('command not found')) {
        setState(() {
          _setupRequired = true;
          _loading = false;
        });
        return;
      }

      final parsed = <String, _CheckResult>{};
      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        _CheckStatus? status;
        String rest = trimmed;

        if (trimmed.startsWith('[PASS]')) {
          status = _CheckStatus.pass;
          rest = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('[FAIL]')) {
          status = _CheckStatus.fail;
          rest = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('[WARN]')) {
          status = _CheckStatus.warn;
          rest = trimmed.substring(6).trim();
        }

        if (status != null) {
          // rest is like "binary: ironclaw binary exists..."
          final colonIdx = rest.indexOf(':');
          final id = colonIdx >= 0 ? rest.substring(0, colonIdx).trim() : rest;
          final desc = colonIdx >= 0 ? rest.substring(colonIdx + 1).trim() : rest;
          parsed[id] = _CheckResult(id, desc, status: status);
        }
      }

      final newResults = _staticChecks.map((c) {
        if (parsed.containsKey(c.$1)) return parsed[c.$1]!;
        return _CheckResult(c.$1, c.$2, status: _CheckStatus.pending);
      }).toList();

      // Add any extra results not in static list
      for (final entry in parsed.entries) {
        if (!_staticChecks.any((c) => c.$1 == entry.key)) {
          newResults.add(entry.value);
        }
      }

      setState(() {
        _results = newResults;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found') || msg.contains('command not found')) {
        setState(() {
          _setupRequired = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _runDoctor,
            child: const Text('Run Again'),
          ),
        ],
      ),
      body: _setupRequired
          ? _buildSetupRequired(theme)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  Text(
                    'Running ironclaw doctor…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_error != null) ...[
                  _buildErrorCard(theme),
                  const SizedBox(height: 16),
                ],
                if (!_loading) _buildSummaryCard(theme),
                if (!_loading) const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.medical_services, size: 14, color: AppColors.mutedText),
                    const SizedBox(width: 6),
                    Text(
                      'HEALTH CHECKS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._results.map((r) => _CheckTile(result: r)),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSetupRequired(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_circle_outlined, size: 64, color: AppColors.statusAmber),
            const SizedBox(height: 16),
            Text('Setup required', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'IronClaw binary not found. Complete the setup wizard first.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryCount(count: _passCount, label: 'PASS', color: AppColors.statusGreen),
          _SummaryCount(count: _failCount, label: 'FAIL', color: AppColors.statusRed),
          _SummaryCount(count: _warnCount, label: 'WARN', color: AppColors.statusAmber),
        ],
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryCount({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  final _CheckResult result;
  const _CheckTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (icon, color) = switch (result.status) {
      _CheckStatus.pass    => (Icons.check_circle, AppColors.statusGreen),
      _CheckStatus.fail    => (Icons.cancel, AppColors.statusRed),
      _CheckStatus.warn    => (Icons.warning, AppColors.statusAmber),
      _CheckStatus.pending => (Icons.circle_outlined, AppColors.statusGrey),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.id,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  result.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
