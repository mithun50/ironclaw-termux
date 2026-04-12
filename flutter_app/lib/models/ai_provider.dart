import 'package:flutter/material.dart';

/// Metadata for an AI model provider that can be configured
/// to power the IronClaw agent.
class AiProvider {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String baseUrl;
  final List<String> defaultModels;
  final String apiKeyHint;
  /// IronClaw provider ID (matches `--provider <id>` CLI flag).
  final String ironclawId;
  /// Environment variable name for this provider's API key.
  final String envVarName;

  const AiProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.baseUrl,
    required this.defaultModels,
    required this.apiKeyHint,
    required this.ironclawId,
    required this.envVarName,
  });

  static const anthropic = AiProvider(
    id: 'anthropic',
    name: 'Anthropic',
    description: 'Claude models — advanced reasoning and coding',
    icon: Icons.psychology,
    color: Color(0xFFD97706),
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModels: [
      'claude-sonnet-4-5-20250514',
      'claude-opus-4-20250514',
      'claude-haiku-4-5-20251001',
    ],
    apiKeyHint: 'sk-ant-...',
    ironclawId: 'anthropic',
    envVarName: 'ANTHROPIC_API_KEY',
  );

  static const openai = AiProvider(
    id: 'openai',
    name: 'OpenAI',
    description: 'GPT-4.1 and o-series models',
    icon: Icons.auto_awesome,
    color: Color(0xFF10A37F),
    baseUrl: 'https://api.openai.com/v1',
    defaultModels: [
      'gpt-4.1',
      'gpt-4.1-mini',
      'gpt-4o',
      'o1',
      'o1-mini',
    ],
    apiKeyHint: 'sk-...',
    ironclawId: 'openai',
    envVarName: 'OPENAI_API_KEY',
  );

  static const google = AiProvider(
    id: 'google',
    name: 'Google Gemini',
    description: 'Gemini family of multimodal models',
    icon: Icons.diamond,
    color: Color(0xFF4285F4),
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    defaultModels: [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
    ],
    apiKeyHint: 'AIza...',
    ironclawId: 'google',
    envVarName: 'GOOGLE_API_KEY',
  );

  static const openrouter = AiProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    description: 'Unified API for 100+ models from all providers',
    icon: Icons.route,
    color: Color(0xFF6366F1),
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModels: [
      'anthropic/claude-sonnet-4-5',
      'openai/gpt-4.1',
      'google/gemini-2.5-pro',
      'meta-llama/llama-3.3-70b-instruct',
    ],
    apiKeyHint: 'sk-or-...',
    ironclawId: 'openrouter',
    envVarName: 'OPENROUTER_API_KEY',
  );

  static const groq = AiProvider(
    id: 'groq',
    name: 'Groq',
    description: 'Ultra-fast inference — preset: fast',
    icon: Icons.flash_on,
    color: Color(0xFFF97316),
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModels: [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'mixtral-8x7b-32768',
    ],
    apiKeyHint: 'gsk_...',
    ironclawId: 'groq',
    envVarName: 'GROQ_API_KEY',
  );

  static const deepseek = AiProvider(
    id: 'deepseek',
    name: 'DeepSeek',
    description: 'High-performance open models — preset: cheap',
    icon: Icons.explore,
    color: Color(0xFF0EA5E9),
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModels: [
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    apiKeyHint: 'sk-...',
    ironclawId: 'deepseek',
    envVarName: 'DEEPSEEK_API_KEY',
  );

  static const mistral = AiProvider(
    id: 'mistral',
    name: 'Mistral',
    description: 'European open-weight models',
    icon: Icons.air,
    color: Color(0xFF7C3AED),
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModels: [
      'mistral-large-latest',
      'mistral-medium-latest',
      'mistral-small-latest',
    ],
    apiKeyHint: 'your-mistral-key',
    ironclawId: 'mistral',
    envVarName: 'MISTRAL_API_KEY',
  );

  static const xai = AiProvider(
    id: 'xai',
    name: 'xAI',
    description: 'Grok models from xAI',
    icon: Icons.bolt,
    color: Color(0xFFEF4444),
    baseUrl: 'https://api.x.ai/v1',
    defaultModels: [
      'grok-3',
      'grok-3-mini',
      'grok-2',
    ],
    apiKeyHint: 'xai-...',
    ironclawId: 'xai',
    envVarName: 'XAI_API_KEY',
  );

  static const nvidia = AiProvider(
    id: 'nvidia',
    name: 'NVIDIA NIM',
    description: 'GPU-optimized inference endpoints',
    icon: Icons.memory,
    color: Color(0xFF76B900),
    baseUrl: 'https://integrate.api.nvidia.com/v1',
    defaultModels: [
      'meta/llama-3.1-405b-instruct',
      'meta/llama-3.3-70b-instruct',
      'deepseek-ai/deepseek-r1',
    ],
    apiKeyHint: 'nvapi-...',
    ironclawId: 'nvidia',
    envVarName: 'NVIDIA_API_KEY',
  );

  /// All available AI providers.
  static const all = [anthropic, openai, google, groq, deepseek, mistral, openrouter, xai, nvidia];
}
