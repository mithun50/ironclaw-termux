import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants.dart';
import '../providers/gateway_provider.dart';
import '../providers/node_provider.dart';
import '../widgets/gateway_controls.dart';
import '../widgets/status_card.dart';
import 'agents_screen.dart';
import 'channels_screen.dart';
import 'clawbook_screen.dart';
import 'doctor_screen.dart';
import 'logs_screen.dart';
import 'node_screen.dart';
import 'packages_screen.dart';
import 'providers_screen.dart';
import 'security_screen.dart';
import 'settings_screen.dart';
import 'skills_screen.dart';
import 'ssh_screen.dart';
import 'audit_screen.dart';
import 'terminal_screen.dart';
import 'web_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    ('Home',      Icons.home_outlined,      Icons.home),
    ('Providers', Icons.model_training,     Icons.model_training),
    ('Security',  Icons.shield_outlined,    Icons.shield),
    ('Channels',  Icons.chat_bubble_outline, Icons.chat_bubble),
    ('More',      Icons.grid_view_outlined,  Icons.grid_view),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeTab(),
          ProvidersScreen(),
          SecurityScreen(),
          ChannelsScreen(),
          _MoreTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.$2),
          selectedIcon: Icon(t.$3, color: AppColors.accent),
          label: t.$1,
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/ironclaw_logo.png', width: 24, height: 24),
            ),
            const SizedBox(width: 8),
            const Text('IronClaw'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatewayControls(),
            const SizedBox(height: 20),
            // Web Dashboard card (gateway-dependent)
            Consumer<GatewayProvider>(
              builder: (context, gw, _) {
                final url = gw.state.dashboardUrl;
                final token = url != null
                    ? RegExp(r'#token=([0-9a-f]+)').firstMatch(url)?.group(1)
                    : null;
                return StatusCard(
                  title: 'Web Dashboard',
                  subtitle: gw.state.isRunning
                      ? (token != null
                          ? 'Token: ${token.substring(0, token.length.clamp(0, 8))}...'
                          : 'Open IronClaw dashboard in browser')
                      : 'Start the gateway first',
                  icon: Icons.dashboard,
                  iconColor: gw.state.isRunning ? AppColors.statusGreen : AppColors.statusGrey,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (token != null)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy URL',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dashboard URL copied')),
                            );
                          },
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: gw.state.isRunning
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WebDashboardScreen(url: url),
                            ),
                          )
                      : null,
                );
              },
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'QUICK ACTIONS', Icons.bolt),
            const SizedBox(height: 10),
            StatusCard(
              title: 'Terminal',
              subtitle: 'Ubuntu shell inside proot — run ironclaw commands',
              icon: Icons.terminal,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TerminalScreen()),
              ),
            ),
            StatusCard(
              title: 'Doctor',
              subtitle: '20 health checks — diagnose issues',
              icon: Icons.medical_services,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorScreen()),
              ),
            ),
            StatusCard(
              title: 'Manage Providers',
              subtitle: 'View configured providers and add or update API keys',
              icon: Icons.model_training,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProvidersScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'BUILT-IN PRESETS', Icons.tune),
            const SizedBox(height: 10),
            _PresetsRow(),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'IronClaw v${AppConstants.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppConstants.authorName} · ${AppConstants.orgName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
}

class _PresetsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = AppConstants.presets.entries.toList();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (context, i) {
          final entry = presets[i];
          final id = entry.key;
          final data = entry.value;
          final color = _presetColor(id);
          final icon = _presetIcon(id);

          return GestureDetector(
            onTap: () => _showPresetInfo(context, id, data),
            child: Container(
              width: 90,
              margin: EdgeInsets.only(right: i < presets.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    id.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    data['provider']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _presetColor(String id) => switch (id) {
    'fast'   => const Color(0xFFF97316),
    'smart'  => const Color(0xFFD97706),
    'cheap'  => const Color(0xFF0EA5E9),
    'local'  => const Color(0xFF374151),
    'vision' => const Color(0xFF4285F4),
    'code'   => const Color(0xFF7C3AED),
    _        => AppColors.mutedText,
  };

  IconData _presetIcon(String id) => switch (id) {
    'fast'   => Icons.flash_on,
    'smart'  => Icons.psychology,
    'cheap'  => Icons.savings,
    'local'  => Icons.computer,
    'vision' => Icons.remove_red_eye,
    'code'   => Icons.code,
    _        => Icons.tune,
  };

  void _showPresetInfo(BuildContext context, String id, Map<String, String> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preset: $id'),
        content: Text(
          '${data['tagline']}\n\n'
          'Provider: ${data['provider']}\n'
          'Model: ${data['model']}\n\n'
          'Run with:\n'
          '  ironclaw run --provider $id --ui',
          style: const TextStyle(fontFamily: 'monospace', height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MORE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _moreSection(context, 'TOOLS', [
            _MoreItem('Skills', Icons.extension, const Color(0xFF22C55E),
                'Install and manage signed skills',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkillsScreen()))),
            _MoreItem('Agents', Icons.hub, AppColors.accent,
                '6 built-in roles · 5 coordination patterns',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgentsScreen()))),
            _MoreItem('Doctor', Icons.medical_services, const Color(0xFF0EA5E9),
                '20 health checks',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorScreen()))),
            _MoreItem('Clawbook', Icons.hub_outlined, const Color(0xFFDC2626),
                'AI agent social network · feed, PRs, communities',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClawbookScreen()))),
          ]),
          const SizedBox(height: 16),
          _moreSection(context, 'SYSTEM', [
            _MoreItem('Terminal', Icons.terminal, const Color(0xFF374151),
                'proot Ubuntu shell',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TerminalScreen()))),
            _MoreItem('Logs', Icons.article_outlined, const Color(0xFF6366F1),
                'Gateway output and errors',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogsScreen()))),
            _MoreItem('Audit Log', Icons.security, const Color(0xFFEF4444),
                'Security events and command history',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditScreen()))),
            _MoreItem('SSH', Icons.lock, const Color(0xFF8B5CF6),
                'Remote terminal access',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SshScreen()))),
            _MoreItem('Packages', Icons.extension_outlined, AppColors.statusAmber,
                'Optional tools — Go, Homebrew',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PackagesScreen()))),
          ]),
          const SizedBox(height: 16),
          _moreSection(context, 'NODE', [
            Consumer<NodeProvider>(
              builder: (context, nodeProvider, _) => _MoreItem(
                'Node',
                Icons.devices,
                const Color(0xFF0DBD8B),
                nodeProvider.state.isPaired ? 'Connected' : nodeProvider.state.statusText,
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NodeScreen())),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _moreSection(context, 'APP', [
            _MoreItem('Settings', Icons.settings_outlined, AppColors.statusGrey,
                'Theme, backups, about',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          ]),
        ],
      ),
    );
  }

  Widget _moreSection(BuildContext context, String label, List<Widget> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreItem(this.title, this.icon, this.color, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: color,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
