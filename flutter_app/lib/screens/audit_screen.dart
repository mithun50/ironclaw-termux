import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../services/native_bridge.dart';

class _AuditEntry {
  final String timestamp;
  final String eventType;
  final String details;
  final String severity;

  const _AuditEntry({
    required this.timestamp,
    required this.eventType,
    required this.details,
    required this.severity,
  });

  factory _AuditEntry.fromJson(Map<String, dynamic> json) => _AuditEntry(
        timestamp: json['timestamp']?.toString() ?? '',
        eventType: json['event_type']?.toString() ?? json['type']?.toString() ?? 'unknown',
        details: json['details']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'info',
      );
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  bool _loading = false;
  bool _setupRequired = false;
  String? _rawOutput;
  List<_AuditEntry> _entries = [];
  String _filter = 'all';
  Timer? _timer;

  static const _filters = [
    ('all', 'All'),
    ('security', 'Security'),
    ('commands', 'Commands'),
    ('errors', 'Errors'),
  ];

  List<_AuditEntry> get _filtered {
    if (_filter == 'all') return _entries;
    return _entries.where((e) {
      final type = e.eventType.toLowerCase();
      final sev = e.severity.toLowerCase();
      return switch (_filter) {
        'security' => type.contains('auth') || type.contains('security') || sev == 'critical' || sev == 'high',
        'commands' => type.contains('command') || type.contains('cmd') || type.contains('exec'),
        'errors'   => sev == 'error' || sev == 'critical' || type.contains('error') || type.contains('fail'),
        _          => true,
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAudit();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAudit());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAudit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _setupRequired = false;
    });

    try {
      final output = await NativeBridge.runInProot('ironclaw audit --count 100');

      if (output.contains('command not found')) {
        setState(() {
          _setupRequired = true;
          _loading = false;
        });
        return;
      }

      final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final entries = <_AuditEntry>[];
      bool jsonFailed = false;

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('{')) continue;
        try {
          final json = jsonDecode(trimmed) as Map<String, dynamic>;
          entries.add(_AuditEntry.fromJson(json));
        } catch (_) {
          jsonFailed = true;
        }
      }

      if (entries.isEmpty && jsonFailed) {
        setState(() {
          _rawOutput = output;
          _entries = [];
          _loading = false;
        });
      } else {
        setState(() {
          _entries = entries;
          _rawOutput = null;
          _loading = false;
        });
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found') || msg.contains('command not found')) {
        setState(() {
          _setupRequired = true;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportToClipboard() async {
    final json = const JsonEncoder.withIndent('  ').convert(
      _entries.map((e) => {
        'timestamp': e.timestamp,
        'event_type': e.eventType,
        'details': e.details,
        'severity': e.severity,
      }).toList(),
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Export to clipboard',
              onPressed: _exportToClipboard,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadAudit,
          ),
        ],
      ),
      body: _setupRequired
          ? _buildSetupRequired(theme)
          : Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: _filters.map((f) {
                      final selected = _filter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f.$1),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_loading)
                  const LinearProgressIndicator(),
                Expanded(
                  child: _rawOutput != null
                      ? _buildRawView(theme)
                      : _filtered.isEmpty
                          ? _buildEmpty(theme)
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) => _AuditTile(entry: _filtered[i]),
                            ),
                ),
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
            const Icon(Icons.security, size: 64, color: AppColors.statusAmber),
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

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No audit entries',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        _rawOutput ?? '',
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final _AuditEntry entry;
  const _AuditTile({required this.entry});

  Color _severityColor() => switch (entry.severity.toLowerCase()) {
        'critical' || 'high'   => AppColors.statusRed,
        'warn' || 'warning'    => AppColors.statusAmber,
        'info'                 => const Color(0xFF0EA5E9),
        _                      => AppColors.statusGrey,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _severityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.eventType.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (entry.timestamp.isNotEmpty)
                Text(
                  _formatTimestamp(entry.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          if (entry.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.length > 19 ? ts.substring(0, 19) : ts;
    }
  }
}
