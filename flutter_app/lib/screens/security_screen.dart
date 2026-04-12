import 'package:flutter/material.dart';
import '../app.dart';
import '../models/security_layer.dart';
import '../widgets/status_card.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.verified_user, size: 16, color: AppColors.statusGreen),
              label: Text(
                '13 LAYERS',
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
          _SectionHeader(
            label: 'DEFENCE IN DEPTH',
            subtitle: 'All layers are active and protecting your agent',
            icon: Icons.shield,
            iconColor: AppColors.statusGreen,
          ),
          const SizedBox(height: 12),
          ...SecurityLayer.all.map((layer) => _SecurityLayerTile(
                layer: layer,
                isDark: isDark,
              )),
          const SizedBox(height: 24),
          _SectionHeader(
            label: 'ANDROID NOTES',
            subtitle: 'Some layers behave differently on Android',
            icon: Icons.android,
            iconColor: AppColors.statusAmber,
          ),
          const SizedBox(height: 12),
          StatusCard(
            title: 'Sandbox Mode: native',
            subtitle:
                'Docker is not available in proot. The proot Ubuntu environment '
                'provides the equivalent isolation boundary. '
                'ironclaw.yaml: sandbox.backend = "native"',
            icon: Icons.lock_outline,
            iconColor: AppColors.statusAmber,
            trailing: const Icon(Icons.info_outline, size: 18),
          ),
          StatusCard(
            title: 'Memory: encrypted_sqlite',
            subtitle:
                'Agent memory is stored in an AES-256-GCM encrypted SQLite '
                'database at /root/.ironclaw/memory.db inside the proot environment.',
            icon: Icons.storage,
            iconColor: AppColors.statusGreen,
            trailing: const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            label: 'AUDIT',
            subtitle: 'Access the tamper-evident event log',
            icon: Icons.history,
            iconColor: AppColors.statusGrey,
          ),
          const SizedBox(height: 12),
          StatusCard(
            title: 'View Audit Log',
            subtitle: 'Run: ironclaw audit --count 50',
            icon: Icons.article_outlined,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAuditInfo(context),
          ),
          StatusCard(
            title: 'Policy Viewer',
            subtitle: 'Run: ironclaw policy',
            icon: Icons.policy,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPolicyInfo(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAuditInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: AppColors.statusGreen),
            SizedBox(width: 8),
            Text('Audit Log'),
          ],
        ),
        content: const Text(
          'The audit log records every agent action, tool call, and security event.\n\n'
          'To view it, open the Terminal and run:\n\n'
          '  ironclaw audit\n  ironclaw audit --count 100\n\n'
          'The log is append-only and tamper-evident.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPolicyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.policy, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Security Policy'),
          ],
        ),
        content: const Text(
          'The security policy is defined in ironclaw.yaml.\n\n'
          'To view the active policy, open the Terminal and run:\n\n'
          '  ironclaw policy\n\n'
          'Key settings:\n'
          '• permissions.system.allow_shell = false\n'
          '• sandbox.backend = "native"\n'
          '• skills.require_signatures = true\n'
          '• memory.backend = "encrypted_sqlite"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SecurityLayerTile extends StatelessWidget {
  final SecurityLayer layer;
  final bool isDark;

  const _SecurityLayerTile({required this.layer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: layer.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(layer.icon, color: layer.color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                layer.name,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ACTIVE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.statusGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          layer.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            layer.details,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          if (layer.configKey.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Config: ${layer.configKey}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.mutedText,
                ),
              ),
            ),
          ],
          if (!layer.androidCompatible) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.android, size: 14, color: AppColors.statusAmber),
                const SizedBox(width: 4),
                Text(
                  'Limited on Android — see notes above',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.statusAmber),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
