import 'package:flutter/material.dart';
import '../app.dart';
import '../models/channel.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'All'),
    ('local', 'Local'),
    ('messaging', 'Messaging'),
    ('api', 'API'),
    ('enterprise', 'Enterprise'),
    ('apple', 'Apple'),
  ];

  List<IronClawChannel> get _filtered => _selectedCategory == 'all'
      ? IronClawChannel.all
      : IronClawChannel.byCategory(_selectedCategory);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '20 CHANNELS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = cat.$1),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _ChannelTile(channel: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final IronClawChannel channel;

  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            color: channel.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(channel.icon, color: channel.color, size: 20),
        ),
        title: Text(
          channel.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          channel.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CategoryBadge(channel.category),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rate limits
          Row(
            children: [
              const Icon(Icons.speed, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(
                'Rate limit: burst ${channel.rateLimitBurst} req, '
                '${channel.rateLimitSteady} req/min',
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Credentials needed
          if (!channel.needsCredentials)
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.statusGreen),
                const SizedBox(width: 4),
                Text(
                  'No credentials required',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.statusGreen),
                ),
              ],
            )
          else ...[
            Text(
              'Required credentials:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: channel.credentialKeys.map((key) => _EnvChip(key)).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Add these to /root/.ironclaw/.env then restart the gateway.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // YAML snippet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'channels:\n  - type: ${channel.type.configValue}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (category) {
      'local'      => AppColors.statusGreen,
      'messaging'  => AppColors.statusAmber,
      'api'        => const Color(0xFF0EA5E9),
      'enterprise' => const Color(0xFF6264A7),
      'apple'      => const Color(0xFF34AADC),
      _            => AppColors.statusGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EnvChip extends StatelessWidget {
  final String label;
  const _EnvChip(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
        ),
      ),
    );
  }
}
