import 'package:flutter/material.dart';
import '../app.dart';
import '../models/skill.dart';
import '../widgets/status_card.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Skills extend IronClaw\'s capabilities. Every skill must be '
                    'signed with Ed25519 and verified with SHA-256 before execution. '
                    'Skills are stored at /root/.ironclaw/skills/ inside proot.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(context, 'MANAGE SKILLS', Icons.extension),
          const SizedBox(height: 10),
          ...SkillCategory.all.map((cat) => _SkillActionCard(
                category: cat,
                isDark: isDark,
              )),
          const SizedBox(height: 20),
          _sectionLabel(context, 'SKILL SECURITY', Icons.verified_user),
          const SizedBox(height: 10),
          StatusCard(
            title: 'Signature Requirement',
            subtitle: 'skills.require_signatures = true in ironclaw.yaml',
            icon: Icons.verified,
            iconColor: AppColors.statusGreen,
            trailing: const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
          ),
          StatusCard(
            title: 'Ed25519 Signatures',
            subtitle: 'Cryptographic proof of skill authenticity and integrity',
            icon: Icons.key,
            iconColor: AppColors.statusGreen,
            trailing: const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
          ),
          StatusCard(
            title: 'SHA-256 Content Hash',
            subtitle: 'Detects any modification to skill files post-signing',
            icon: Icons.fingerprint,
            iconColor: AppColors.statusGreen,
            trailing: const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
          ),
          StatusCard(
            title: 'Malware Scanner',
            subtitle: 'ironclaw skill scan checks for known malicious patterns',
            icon: Icons.security_update_warning,
            iconColor: AppColors.statusAmber,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showScanInfo(context),
          ),
          const SizedBox(height: 20),
          _sectionLabel(context, 'USAGE', Icons.code),
          const SizedBox(height: 10),
          _CodeBlock(
            isDark: isDark,
            code:
                '# Inside proot terminal:\nironclaw skill list\nironclaw skill verify\nironclaw skill scan\nironclaw skill install <name>',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  void _showScanInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security_update_warning, color: AppColors.statusAmber),
            SizedBox(width: 8),
            Text('Skill Scanner'),
          ],
        ),
        content: const Text(
          'The skill scanner checks for:\n\n'
          '• Reverse shell patterns\n'
          '• Credential harvesting code\n'
          '• Suspicious network calls\n'
          '• Known malware signatures\n'
          '• Unsafe file operations\n\n'
          'Run it with: ironclaw skill scan\n\n'
          'Open the Terminal tab to run this command.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SkillActionCard extends StatelessWidget {
  final SkillCategory category;
  final bool isDark;

  const _SkillActionCard({required this.category, required this.isDark});

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
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          category.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category.ironclawSubcommands.first,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              color: AppColors.mutedText,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final bool isDark;
  final String code;

  const _CodeBlock({required this.isDark, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: Text(
        code,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.6,
        ),
      ),
    );
  }
}
