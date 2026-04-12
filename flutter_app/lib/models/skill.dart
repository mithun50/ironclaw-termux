import 'package:flutter/material.dart';

/// One of IronClaw's 6 built-in presets.
/// Source: ironclaw/src/main.rs preset match arm.
class IronClawPreset {
  final String id;
  final String name;
  final String providerId; // matches AiProvider.id
  final String model;
  final String tagline;
  final String description;
  final IconData icon;
  final Color color;

  const IronClawPreset({
    required this.id,
    required this.name,
    required this.providerId,
    required this.model,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const fast = IronClawPreset(
    id: 'fast',
    name: 'Fast',
    providerId: 'groq',
    model: 'llama-3.3-70b-versatile',
    tagline: 'Ultra-fast Groq inference',
    description: 'Groq\'s custom silicon delivers sub-second response times. '
        'Best for interactive tasks where speed matters most.',
    icon: Icons.flash_on,
    color: Color(0xFFF97316),
  );

  static const smart = IronClawPreset(
    id: 'smart',
    name: 'Smart',
    providerId: 'anthropic',
    model: 'claude-sonnet-4-5-20250514',
    tagline: 'Highest quality reasoning',
    description: 'Claude Sonnet provides best-in-class reasoning, analysis, '
        'and instruction following. Ideal for complex tasks.',
    icon: Icons.psychology,
    color: Color(0xFFD97706),
  );

  static const cheap = IronClawPreset(
    id: 'cheap',
    name: 'Cheap',
    providerId: 'deepseek',
    model: 'deepseek-chat',
    tagline: 'Lowest cost option',
    description: 'DeepSeek offers GPT-4-level quality at a fraction of the cost. '
        'Perfect for high-volume workloads.',
    icon: Icons.savings,
    color: Color(0xFF0EA5E9),
  );

  static const local = IronClawPreset(
    id: 'local',
    name: 'Local',
    providerId: 'ollama',
    model: 'llama3.3',
    tagline: 'No API key — on-device',
    description: 'Runs entirely on your device via Ollama. '
        'No data leaves the device, no API costs, works offline.',
    icon: Icons.computer,
    color: Color(0xFF374151),
  );

  static const vision = IronClawPreset(
    id: 'vision',
    name: 'Vision',
    providerId: 'google',
    model: 'gemini-2.5-flash',
    tagline: 'Multimodal vision tasks',
    description: 'Gemini 2.5 Flash excels at image understanding, '
        'chart analysis, and mixed media tasks.',
    icon: Icons.remove_red_eye,
    color: Color(0xFF4285F4),
  );

  static const code = IronClawPreset(
    id: 'code',
    name: 'Code',
    providerId: 'anthropic',
    model: 'claude-sonnet-4-5-20250514',
    tagline: 'Code generation & review',
    description: 'Claude is the top-ranked model for coding tasks — '
        'writing, debugging, and architecture decisions.',
    icon: Icons.code,
    color: Color(0xFF7C3AED),
  );

  static const all = [fast, smart, cheap, local, vision, code];
}

/// Categories of skills that IronClaw can scan and install.
class SkillCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> ironclawSubcommands;

  const SkillCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.ironclawSubcommands,
  });

  static const all = [
    SkillCategory(
      id: 'list',
      name: 'List Skills',
      description: 'Show all installed skills with verification status',
      icon: Icons.list,
      color: Color(0xFF22C55E),
      ironclawSubcommands: ['skill list'],
    ),
    SkillCategory(
      id: 'install',
      name: 'Install Skill',
      description: 'Install a skill from a verified source',
      icon: Icons.download,
      color: Color(0xFF0EA5E9),
      ironclawSubcommands: ['skill install'],
    ),
    SkillCategory(
      id: 'verify',
      name: 'Verify Skills',
      description: 'Re-verify Ed25519 signatures on all skills',
      icon: Icons.verified,
      color: Color(0xFF8B5CF6),
      ironclawSubcommands: ['skill verify'],
    ),
    SkillCategory(
      id: 'scan',
      name: 'Scan for Threats',
      description: 'Scan skills for malicious patterns',
      icon: Icons.security_update_warning,
      color: Color(0xFFEF4444),
      ironclawSubcommands: ['skill scan'],
    ),
  ];
}
