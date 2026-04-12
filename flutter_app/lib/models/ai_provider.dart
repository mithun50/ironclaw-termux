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
  /// Whether this provider requires an API key (false for ollama, lmstudio).
  final bool requiresApiKey;

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
    this.requiresApiKey = true,
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

  static const ollama = AiProvider(
    id: 'ollama',
    name: 'Ollama',
    description: 'Local models on-device — preset: local',
    icon: Icons.computer,
    color: Color(0xFF374151),
    baseUrl: 'http://localhost:11434/v1',
    defaultModels: ['llama3.3', 'llama3.2', 'mistral', 'phi3', 'codellama', 'gemma2'],
    apiKeyHint: 'ollama (no key needed)',
    ironclawId: 'ollama',
    envVarName: 'OLLAMA_API_KEY',
    requiresApiKey: false,
  );

  static const cohere = AiProvider(
    id: 'cohere',
    name: 'Cohere',
    description: 'Command R+ models — enterprise RAG',
    icon: Icons.hub,
    color: Color(0xFF39B3F2),
    baseUrl: 'https://api.cohere.ai/v2',
    defaultModels: ['command-r-plus-08-2024', 'command-r-08-2024', 'command-light'],
    apiKeyHint: 'your-cohere-key',
    ironclawId: 'cohere',
    envVarName: 'COHERE_API_KEY',
  );

  static const together = AiProvider(
    id: 'together',
    name: 'Together AI',
    description: 'Open-source model hosting at scale',
    icon: Icons.groups,
    color: Color(0xFF7C3AED),
    baseUrl: 'https://api.together.xyz/v1',
    defaultModels: [
      'meta-llama/Llama-3-70b-chat-hf',
      'meta-llama/Llama-3.3-70B-Instruct-Turbo',
      'mistralai/Mixtral-8x22B-Instruct-v0.1',
      'deepseek-ai/DeepSeek-R1',
    ],
    apiKeyHint: 'your-together-key',
    ironclawId: 'together',
    envVarName: 'TOGETHER_API_KEY',
  );

  static const fireworks = AiProvider(
    id: 'fireworks',
    name: 'Fireworks AI',
    description: 'Fast open-model inference',
    icon: Icons.local_fire_department,
    color: Color(0xFFF97316),
    baseUrl: 'https://api.fireworks.ai/inference/v1',
    defaultModels: [
      'accounts/fireworks/models/llama-v3p3-70b-instruct',
      'accounts/fireworks/models/deepseek-r1',
    ],
    apiKeyHint: 'fw_...',
    ironclawId: 'fireworks',
    envVarName: 'FIREWORKS_API_KEY',
  );

  static const perplexity = AiProvider(
    id: 'perplexity',
    name: 'Perplexity',
    description: 'Online search-augmented reasoning',
    icon: Icons.search,
    color: Color(0xFF20B2AA),
    baseUrl: 'https://api.perplexity.ai',
    defaultModels: [
      'sonar-pro',
      'sonar',
      'sonar-reasoning-pro',
      'sonar-reasoning',
    ],
    apiKeyHint: 'pplx-...',
    ironclawId: 'perplexity',
    envVarName: 'PERPLEXITY_API_KEY',
  );

  static const cerebras = AiProvider(
    id: 'cerebras',
    name: 'Cerebras',
    description: 'Extreme-speed inference on wafer-scale chips',
    icon: Icons.speed,
    color: Color(0xFFEC4899),
    baseUrl: 'https://api.cerebras.ai/v1',
    defaultModels: ['llama-3.3-70b', 'llama-3.1-8b'],
    apiKeyHint: 'csk-...',
    ironclawId: 'cerebras',
    envVarName: 'CEREBRAS_API_KEY',
  );

  static const sambanova = AiProvider(
    id: 'sambanova',
    name: 'SambaNova',
    description: 'High-throughput inference platform',
    icon: Icons.data_usage,
    color: Color(0xFF8B5CF6),
    baseUrl: 'https://fast-api.snova.ai/v1',
    defaultModels: ['Meta-Llama-3.3-70B-Instruct', 'Meta-Llama-3.1-405B-Instruct'],
    apiKeyHint: 'your-sambanova-key',
    ironclawId: 'sambanova',
    envVarName: 'SAMBANOVA_API_KEY',
  );

  static const azure = AiProvider(
    id: 'azure',
    name: 'Azure OpenAI',
    description: 'OpenAI models via Microsoft Azure',
    icon: Icons.cloud,
    color: Color(0xFF0078D4),
    baseUrl: 'https://{resource}.openai.azure.com',
    defaultModels: ['gpt-4o', 'gpt-4.1', 'o1'],
    apiKeyHint: 'your-azure-key',
    ironclawId: 'azure_openai',
    envVarName: 'AZURE_OPENAI_API_KEY',
  );

  static const vertexai = AiProvider(
    id: 'vertexai',
    name: 'Vertex AI',
    description: 'Google Cloud enterprise AI platform',
    icon: Icons.cloud_done,
    color: Color(0xFF34A853),
    baseUrl: 'https://us-central1-aiplatform.googleapis.com/v1',
    defaultModels: ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash-001'],
    apiKeyHint: 'your-gcp-project-id',
    ironclawId: 'vertex_ai',
    envVarName: 'GOOGLE_CLOUD_PROJECT',
  );

  static const bedrock = AiProvider(
    id: 'bedrock',
    name: 'AWS Bedrock',
    description: 'Managed foundation models on AWS',
    icon: Icons.dns,
    color: Color(0xFFFF9900),
    baseUrl: 'https://bedrock.us-east-1.amazonaws.com',
    defaultModels: [
      'anthropic.claude-3-5-sonnet-20241022-v2:0',
      'amazon.nova-pro-v1:0',
      'meta.llama3-3-70b-instruct-v1:0',
    ],
    apiKeyHint: 'AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY',
    ironclawId: 'bedrock',
    envVarName: 'AWS_ACCESS_KEY_ID',
  );

  static const cloudflare = AiProvider(
    id: 'cloudflare',
    name: 'Cloudflare AI',
    description: 'Edge AI inference via Workers AI',
    icon: Icons.public,
    color: Color(0xFFF6821F),
    baseUrl: 'https://api.cloudflare.com/client/v4/accounts/{id}/ai/v1',
    defaultModels: [
      '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
      '@cf/deepseek-ai/deepseek-r1-distill-qwen-32b',
    ],
    apiKeyHint: 'your-cloudflare-token',
    ironclawId: 'cloudflare',
    envVarName: 'CLOUDFLARE_API_TOKEN',
  );

  static const huggingface = AiProvider(
    id: 'huggingface',
    name: 'HuggingFace',
    description: 'Inference API for any HF model',
    icon: Icons.face,
    color: Color(0xFFFFD21E),
    baseUrl: 'https://api-inference.huggingface.co',
    defaultModels: [
      'meta-llama/Llama-3.3-70B-Instruct',
      'mistralai/Mistral-7B-Instruct-v0.3',
    ],
    apiKeyHint: 'hf_...',
    ironclawId: 'huggingface',
    envVarName: 'HF_API_TOKEN',
  );

  static const replicate = AiProvider(
    id: 'replicate',
    name: 'Replicate',
    description: 'Run any open model in the cloud',
    icon: Icons.content_copy,
    color: Color(0xFF6366F1),
    baseUrl: 'https://api.replicate.com/v1',
    defaultModels: [
      'meta/meta-llama-3-70b-instruct',
      'mistralai/mixtral-8x7b-instruct-v0.1',
    ],
    apiKeyHint: 'r8_...',
    ironclawId: 'replicate',
    envVarName: 'REPLICATE_API_TOKEN',
  );

  static const lepton = AiProvider(
    id: 'lepton',
    name: 'Lepton AI',
    description: 'Scalable LLM serving infrastructure',
    icon: Icons.scatter_plot,
    color: Color(0xFF0EA5E9),
    baseUrl: 'https://llama3-3-70b.lepton.run/api/v1',
    defaultModels: ['llama3-70b', 'mixtral-8x7b'],
    apiKeyHint: 'your-lepton-key',
    ironclawId: 'lepton',
    envVarName: 'LEPTON_API_KEY',
  );

  static const lmstudio = AiProvider(
    id: 'lmstudio',
    name: 'LM Studio',
    description: 'Local LLM server on desktop (OpenAI-compat)',
    icon: Icons.laptop,
    color: Color(0xFF64748B),
    baseUrl: 'http://localhost:1234/v1',
    defaultModels: ['local-model'],
    apiKeyHint: 'lm-studio (no key needed)',
    ironclawId: 'lmstudio',
    envVarName: 'LMSTUDIO_API_KEY',
    requiresApiKey: false,
  );

  static const ai21 = AiProvider(
    id: 'ai21',
    name: 'AI21 Labs',
    description: 'Jamba long-context models',
    icon: Icons.subject,
    color: Color(0xFF7C3AED),
    baseUrl: 'https://api.ai21.com/studio/v1',
    defaultModels: ['jamba-1.5-large', 'jamba-1.5-mini'],
    apiKeyHint: 'your-ai21-key',
    ironclawId: 'ai21',
    envVarName: 'AI21_API_KEY',
  );

  /// All available AI providers, grouped: cloud → local → self-hosted.
  static const all = [
    // Tier 1 — cloud flagships
    anthropic, openai, google, groq, deepseek, mistral,
    // Tier 2 — aggregators / routers
    openrouter,
    // Tier 3 — specialised cloud
    xai, nvidia, cohere, together, fireworks, perplexity,
    cerebras, sambanova, azure, vertexai, bedrock,
    cloudflare, huggingface, replicate, lepton, ai21,
    // Tier 4 — local / self-hosted
    ollama, lmstudio,
  ];

  /// Tier label for display grouping.
  String get tier {
    const localIds = {'ollama', 'lmstudio'};
    const routerIds = {'openrouter'};
    const cloudIds = {'anthropic', 'openai', 'google', 'groq', 'deepseek', 'mistral',
      'xai', 'nvidia', 'cohere', 'together', 'fireworks', 'perplexity',
      'cerebras', 'sambanova', 'azure', 'vertexai', 'bedrock',
      'cloudflare', 'huggingface', 'replicate', 'lepton', 'ai21'};
    if (localIds.contains(id)) return 'Local';
    if (routerIds.contains(id)) return 'Router';
    if (cloudIds.contains(id)) return 'Cloud';
    return 'Cloud';
  }
}
