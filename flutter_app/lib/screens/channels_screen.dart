import 'package:flutter/material.dart';
import '../app.dart';
import '../models/channel.dart';
import '../services/native_bridge.dart';
import '../services/provider_config_service.dart';

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

  void _openDetail(IronClawChannel channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChannelDetailSheet(channel: channel),
    );
  }

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
              itemBuilder: (context, i) => _ChannelCard(
                channel: _filtered[i],
                onTap: () => _openDetail(_filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final IronClawChannel channel;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: channel.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(channel.icon, color: channel.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    channel.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CategoryBadge(channel.category),
            const SizedBox(width: 8),
            if (channel.needsCredentials)
              const Icon(Icons.lock_outline, size: 16, color: AppColors.mutedText)
            else
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusGreen),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Sheet ────────────────────────────────────────────────────────────

class _ChannelDetailSheet extends StatefulWidget {
  final IronClawChannel channel;
  const _ChannelDetailSheet({required this.channel});

  @override
  State<_ChannelDetailSheet> createState() => _ChannelDetailSheetState();
}

class _ChannelDetailSheetState extends State<_ChannelDetailSheet> {
  bool _loading = true;
  bool _saving = false;
  Map<String, String> _envMap = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _enabled = false;

  String get _enabledKey =>
      'CHANNEL_${widget.channel.type.configValue.toUpperCase()}_ENABLED';

  @override
  void initState() {
    super.initState();
    for (final key in widget.channel.credentialKeys) {
      _controllers[key] = TextEditingController();
    }
    _loadEnv();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEnv() async {
    try {
      final content = await NativeBridge.readRootfsFile('root/.ironclaw/.env');
      final map = _parseEnv(content ?? '');
      setState(() {
        _envMap = map;
        for (final key in widget.channel.credentialKeys) {
          _controllers[key]?.text = map[key] ?? '';
        }
        final enabledVal = map[_enabledKey]?.toLowerCase();
        _enabled = enabledVal == 'true' || enabledVal == '1';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Map<String, String> _parseEnv(String content) {
    final map = <String, String>{};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx < 0) continue;
      final k = trimmed.substring(0, idx).trim();
      final v = trimmed.substring(idx + 1).trim();
      map[k] = v;
    }
    return map;
  }

  String _serializeEnv(Map<String, String> map) {
    return map.entries.map((e) => '${e.key}=${e.value}').join('\n') + '\n';
  }

  Future<void> _saveCredentials() async {
    setState(() => _saving = true);
    try {
      final content = await NativeBridge.readRootfsFile('root/.ironclaw/.env');
      final map = _parseEnv(content ?? '');

      for (final key in widget.channel.credentialKeys) {
        final val = _controllers[key]?.text.trim() ?? '';
        if (val.isEmpty) {
          map.remove(key);
        } else {
          map[key] = val;
        }
      }
      map[_enabledKey] = _enabled ? 'true' : 'false';

      await NativeBridge.writeRootfsFile('root/.ironclaw/.env', _serializeEnv(map));

      // Notify other widgets via configChangedListenable
      final yaml = await ProviderConfigService.readConfigYaml();
      await ProviderConfigService.writeConfigYaml(yaml ?? '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credentials saved')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final channel = widget.channel;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: channel.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(channel.icon, color: channel.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            channel.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CategoryBadge(channel.category),
                  ],
                ),
                const SizedBox(height: 16),
                // Rate limits
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 16, color: AppColors.mutedText),
                      const SizedBox(width: 8),
                      Text(
                        'Burst: ${channel.rateLimitBurst} req  •  Steady: ${channel.rateLimitSteady} req/min',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Enable/Disable
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable channel'),
                  subtitle: Text(_enabledKey),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const Divider(),
                // Credentials
                if (channel.needsCredentials) ...[
                  const SizedBox(height: 8),
                  Text(
                    'CREDENTIALS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...channel.credentialKeys.map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[key],
                        obscureText: key.toLowerCase().contains('secret') ||
                            key.toLowerCase().contains('token') ||
                            key.toLowerCase().contains('key'),
                        decoration: InputDecoration(
                          labelText: key,
                          hintText: 'Enter $key',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.statusGreen),
                      const SizedBox(width: 8),
                      Text(
                        'No credentials required',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.statusGreen),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Save button
                FilledButton(
                  onPressed: _saving ? null : _saveCredentials,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Credentials'),
                ),
                const SizedBox(height: 20),
                // YAML snippet
                Text(
                  'CONFIG SNIPPET',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'channels:\n  - type: ${channel.type.configValue}',
                    style: theme.textTheme.bodySmall?.copyWith(
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

// ─── Shared widgets ───────────────────────────────────────────────────────────

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
