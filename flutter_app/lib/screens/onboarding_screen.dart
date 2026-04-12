import 'package:flutter/material.dart';
import '../app.dart';
import '../models/ai_provider.dart';
import '../services/provider_config_service.dart';
import '../services/preferences_service.dart';
import 'dashboard_screen.dart';

/// Flutter form screen to configure an AI provider API key.
/// Shown after first-time setup and accessible from the providers list.
class OnboardingScreen extends StatefulWidget {
  /// If true, navigates to the dashboard after saving instead of popping.
  final bool isFirstRun;

  const OnboardingScreen({super.key, this.isFirstRun = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _customModelSentinel = '__custom__';

  AiProvider _selectedProvider = AiProvider.anthropic;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _customModelController;
  late String _selectedModel;
  bool _isCustomModel = false;
  bool _obscureKey = true;
  bool _saving = false;

  String get _effectiveModel =>
      _isCustomModel ? _customModelController.text.trim() : _selectedModel;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _customModelController = TextEditingController();
    _selectedModel = _selectedProvider.defaultModels.first;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProvider? provider) {
    if (provider == null) return;
    setState(() {
      _selectedProvider = provider;
      _selectedModel = provider.defaultModels.first;
      _isCustomModel = false;
      _apiKeyController.clear();
    });
  }

  Future<void> _save() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key cannot be empty')),
      );
      return;
    }
    final model = _effectiveModel;
    if (model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ProviderConfigService.saveProviderConfig(
        provider: _selectedProvider,
        apiKey: apiKey,
        model: model,
      );
      if (!mounted) return;

      if (widget.isFirstRun) {
        final prefs = PreferencesService();
        await prefs.init();
        prefs.setupComplete = true;
        prefs.isFirstRun = false;
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedProvider.name} configured and activated')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstRun ? 'Configure Provider' : 'Add Provider'),
        leading: widget.isFirstRun
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.isFirstRun) ...[
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/ironclaw_logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Configure Your AI Provider',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your API key to start using IronClaw.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],

          // Provider picker
          Text(
            'AI Provider',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AiProvider>(
            value: _selectedProvider,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: AiProvider.all.map((p) => DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(p.icon, color: p.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )).toList(),
            onChanged: _onProviderChanged,
          ),
          const SizedBox(height: 6),
          Text(
            _selectedProvider.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // API Key
          Text(
            'API Key',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: _selectedProvider.apiKeyHint,
              helperText: 'Stored as ${_selectedProvider.envVarName} — never leaves the device',
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model selection
          Text(
            'Model',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              ..._selectedProvider.defaultModels.map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m, overflow: TextOverflow.ellipsis),
                ),
              ),
              const DropdownMenuItem(
                value: _customModelSentinel,
                child: Text('Custom...'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedModel = value;
                  _isCustomModel = value == _customModelSentinel;
                });
              }
            },
          ),
          if (_isCustomModel) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customModelController,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'e.g. claude-3-5-sonnet-20241022',
                labelText: 'Custom model name',
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Save button
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(widget.isFirstRun ? Icons.arrow_forward : Icons.save),
            label: Text(widget.isFirstRun ? 'Save & Continue' : 'Save & Activate'),
          ),
        ],
      ),
    );
  }
}
