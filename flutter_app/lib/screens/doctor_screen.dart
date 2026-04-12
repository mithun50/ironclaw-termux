import 'package:flutter/material.dart';
import '../app.dart';

/// Displays the 20 IronClaw doctor health checks.
/// Source: ironclaw/src/main.rs + QUICKSTART.md
class DoctorScreen extends StatelessWidget {
  const DoctorScreen({super.key});

  static const _checks = [
    _HealthCheck('binary', 'ironclaw binary', 'ironclaw binary exists and is executable', true),
    _HealthCheck('version', 'Version match', 'Installed version matches expected release', true),
    _HealthCheck('config', 'Config file', '~/.ironclaw/config.yaml or ./ironclaw.yaml present', true),
    _HealthCheck('env_file', '.env file', '/root/.ironclaw/.env exists with at least one key', true),
    _HealthCheck('api_key', 'API key set', 'Active provider has a valid API key configured', true),
    _HealthCheck('provider', 'Provider reachable', 'Active provider endpoint responds to a ping', true),
    _HealthCheck('memory_db', 'Memory database', 'AES-256-GCM encrypted SQLite memory.db writable', true),
    _HealthCheck('sandbox', 'Sandbox mode', 'sandbox.backend = "native" (Docker n/a on Android)', true),
    _HealthCheck('permissions', 'Permissions', 'RBAC deny-first policy loaded', true),
    _HealthCheck('skills_dir', 'Skills directory', '/root/.ironclaw/skills/ exists', true),
    _HealthCheck('skill_sigs', 'Skill signatures', 'All installed skills have valid Ed25519 signatures', true),
    _HealthCheck('audit_log', 'Audit log', 'Audit log file is writable and not corrupted', true),
    _HealthCheck('dlp', 'DLP engine', 'Data loss prevention patterns loaded', true),
    _HealthCheck('ssrf', 'SSRF guard', 'SSRF blocklist includes cloud metadata endpoints', true),
    _HealthCheck('rate_limit', 'Rate limiting', 'Token-bucket rate limiter initialised', true),
    _HealthCheck('web_ui', 'Web UI', 'Web UI can bind to port 3000', true),
    _HealthCheck('session_auth', 'Session auth', 'HMAC-SHA256 session token generation works', true),
    _HealthCheck('ssl', 'SSL certificates', 'ca-certificates installed (for HTTPS calls)', true),
    _HealthCheck('proot', 'proot isolation', 'proot environment is functional', true),
    _HealthCheck('rust_env', 'Rust environment', 'RUST_LOG and PATH include /root/.cargo/bin', true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.check_circle, size: 14, color: AppColors.statusGreen),
              label: Text(
                '20 CHECKS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.statusGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: AppColors.statusGreen.withOpacity(0.12),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Run live check banner
          _LiveCheckBanner(),
          const SizedBox(height: 20),
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
          ..._checks.map((check) => _CheckTile(check: check)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LiveCheckBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, color: AppColors.statusGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Run Live Diagnostics',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'For a real-time health check, open the Terminal and run:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ironclaw doctor',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: AppColors.statusGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IronClaw runs 20 checks and prints ✅ / ❌ / ⚠️ for each one.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final _HealthCheck check;

  const _CheckTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  check.description,
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

class _HealthCheck {
  final String id;
  final String name;
  final String description;
  final bool critical;

  const _HealthCheck(this.id, this.name, this.description, this.critical);
}
