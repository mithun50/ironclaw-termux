import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../constants.dart';
import '../models/ai_provider.dart';
import '../models/gateway_state.dart';
import '../providers/gateway_provider.dart';
import '../screens/logs_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/web_dashboard_screen.dart';
import '../services/provider_config_service.dart';

class GatewayControls extends StatefulWidget {
  const GatewayControls({super.key});

  @override
  State<GatewayControls> createState() => _GatewayControlsState();
}

class _GatewayControlsState extends State<GatewayControls> {
  Future<void> _openRuntimePicker(BuildContext context) async {
    final config = await ProviderConfigService.readConfig();
    final configuredProviders = AiProvider.all.where((provider) {
      return (config['providers'] as Map<String, dynamic>? ?? {}).containsKey(provider.id);
    }).toList();

    if (!mounted) return;

    if (configuredProviders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure a provider first')),
      );
      return;
    }

    final currentProviderId = config['activeProvider'] as String?;
    final currentModel = config['activeModel'] as String?;
    final providerData = config['providers'] as Map<String, dynamic>? ?? {};

    var selectedProvider = configuredProviders.firstWhere(
      (provider) => provider.ironclawId == currentProviderId,
      orElse: () => configuredProviders.first,
    );
    var selectedModel =
        ((providerData[selectedProvider.id] as Map<String, dynamic>?)?['model'] as String?) ??
        (selectedProvider.ironclawId == currentProviderId ? currentModel : null) ??
        selectedProvider.defaultModels.first;

    final selection = await showModalBottomSheet<_RuntimeSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final providerEntry =
                providerData[selectedProvider.id] as Map<String, dynamic>?;
            final storedModel = providerEntry?['model'] as String?;
            final availableModels = <String>[
              ...selectedProvider.defaultModels,
              if (storedModel != null &&
                  storedModel.isNotEmpty &&
                  !selectedProvider.defaultModels.contains(storedModel))
                storedModel,
            ];

            if (!availableModels.contains(selectedModel)) {
              selectedModel = availableModels.first;
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gateway runtime',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose which configured provider and model IronClaw should run with.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Provider',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AiProvider>(
                      value: selectedProvider,
                      isExpanded: true,
                      items: configuredProviders
                          .map(
                            (provider) => DropdownMenuItem(
                              value: provider,
                              child: Text(provider.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedProvider = value;
                          selectedModel =
                              ((providerData[value.id] as Map<String, dynamic>?)?['model']
                                      as String?) ??
                                  value.defaultModels.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Model',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedModel,
                      isExpanded: true,
                      items: availableModels
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedModel = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(
                            _RuntimeSelection(
                              provider: selectedProvider,
                              model: selectedModel,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Use for gateway'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selection == null) return;

    await ProviderConfigService.setActiveProviderConfig(
      provider: selection.provider,
      model: selection.model,
    );

    if (!mounted) return;

    setState(() {});

    final gatewayProvider = context.read<GatewayProvider>();
    if (gatewayProvider.state.isRunning) {
      final restart = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restart Gateway?'),
          content: Text(
            'Switch to ${selection.provider.name} with `${selection.model}` now?\n\n'
            'IronClaw needs a restart to use the new runtime selection.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Restart Now'),
            ),
          ],
        ),
      );

      if (restart == true) {
        await gatewayProvider.stop();
        await Future.delayed(const Duration(milliseconds: 800));
        await gatewayProvider.start();
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gateway runtime set to ${selection.provider.name} · ${selection.model}',
        ),
      ),
    );
  }

  Future<void> _openProviderSetup(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(isFirstRun: false),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<GatewayProvider>(
      builder: (context, provider, _) {
        final state = provider.state;

        return FutureBuilder<Map<String, dynamic>>(
          future: ProviderConfigService.readConfig(),
          builder: (context, snapshot) {
            final config = snapshot.data ?? const <String, dynamic>{};
            final providersMap = config['providers'] as Map<String, dynamic>? ?? {};
            final activeProviderId = config['activeProvider'] as String?;
            final activeModel = config['activeModel'] as String?;

            final configuredProviders = AiProvider.all.where((provider) {
              return providersMap.containsKey(provider.id);
            }).toList();

            AiProvider? activeProvider;
            for (final provider in AiProvider.all) {
              if (provider.ironclawId == activeProviderId) {
                activeProvider = provider;
                break;
              }
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gateway',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _statusBadge(state.status, theme),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.isRunning) ...[
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WebDashboardScreen(
                                      url: state.dashboardUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                state.dashboardUrl ?? AppConstants.gatewayUrl,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontFamily: 'monospace',
                                  decoration: TextDecoration.underline,
                                  decorationColor: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy URL',
                            onPressed: () {
                              final url = state.dashboardUrl ?? AppConstants.gatewayUrl;
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            tooltip: 'Open dashboard',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WebDashboardScreen(
                                    url: state.dashboardUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    if (state.errorMessage != null)
                      Text(
                        state.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    const SizedBox(height: 16),
                    _RuntimeSummaryCard(
                      activeProvider: activeProvider,
                      activeModel: activeModel,
                      configuredProviders: configuredProviders,
                      providersMap: providersMap,
                      onConfigure: () => _openProviderSetup(context),
                      onChangeRuntime: configuredProviders.isEmpty
                          ? null
                          : () => _openRuntimePicker(context),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (state.isStopped || state.status == GatewayStatus.error)
                          FilledButton.icon(
                            onPressed: configuredProviders.isEmpty
                                ? null
                                : () => provider.start(),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Gateway'),
                          ),
                        if (state.isRunning || state.status == GatewayStatus.starting)
                          OutlinedButton.icon(
                            onPressed: () => provider.stop(),
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Gateway'),
                          ),
                        OutlinedButton.icon(
                          onPressed: configuredProviders.isEmpty
                              ? () => _openProviderSetup(context)
                              : () => _openRuntimePicker(context),
                          icon: const Icon(Icons.tune),
                          label: const Text('Select Model'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LogsScreen()),
                          ),
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('View Logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(GatewayStatus status, ThemeData theme) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case GatewayStatus.running:
        color = AppColors.statusGreen;
        label = 'Running';
        icon = Icons.check_circle_outline;
      case GatewayStatus.starting:
        color = AppColors.statusAmber;
        label = 'Starting';
        icon = Icons.hourglass_top;
      case GatewayStatus.error:
        color = AppColors.statusRed;
        label = 'Error';
        icon = Icons.error_outline;
      case GatewayStatus.stopped:
        color = AppColors.statusGrey;
        label = 'Stopped';
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeSummaryCard extends StatelessWidget {
  final AiProvider? activeProvider;
  final String? activeModel;
  final List<AiProvider> configuredProviders;
  final Map<String, dynamic> providersMap;
  final VoidCallback onConfigure;
  final VoidCallback? onChangeRuntime;

  const _RuntimeSummaryCard({
    required this.activeProvider,
    required this.activeModel,
    required this.configuredProviders,
    required this.providersMap,
    required this.onConfigure,
    required this.onChangeRuntime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              Text(
                'Runtime selection',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (configuredProviders.isEmpty) ...[
            Text(
              'No providers are configured yet. Add one to start the gateway.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Configure Provider'),
            ),
          ] else ...[
            _summaryRow(
              context,
              'Active provider',
              activeProvider?.name ?? 'Not selected',
            ),
            const SizedBox(height: 8),
            _summaryRow(
              context,
              'Active model',
              activeModel?.isNotEmpty == true ? activeModel! : 'Not selected',
            ),
            const SizedBox(height: 14),
            Text(
              'Configured providers',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: configuredProviders.map((provider) {
                final model =
                    (providersMap[provider.id] as Map<String, dynamic>?)?['model'] as String?;
                final isActive = activeProvider?.id == provider.id ||
                    activeProvider?.ironclawId == provider.ironclawId;
                return Chip(
                  avatar: Icon(provider.icon, size: 16, color: provider.color),
                  label: Text(
                    model != null && model.isNotEmpty
                        ? '${provider.name} · $model'
                        : provider.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: isActive
                      ? provider.color.withOpacity(0.14)
                      : theme.colorScheme.surface,
                  side: BorderSide(
                    color: isActive
                        ? provider.color.withOpacity(0.45)
                        : theme.colorScheme.outlineVariant,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onChangeRuntime,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change Runtime'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onConfigure,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Provider'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuntimeSelection {
  final AiProvider provider;
  final String model;

  const _RuntimeSelection({
    required this.provider,
    required this.model,
  });
}
