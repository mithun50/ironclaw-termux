import 'package:flutter/material.dart';

/// One of IronClaw's 13 defence-in-depth security layers.
/// Source: ironclaw/src/security/mod.rs + docs/SECURITY_AUDIT.md
class SecurityLayer {
  final int layerIndex; // 1-13
  final String id;
  final String name;
  final String description;
  final String details;
  final IconData icon;
  final Color color;
  /// Path in ironclaw.yaml that controls this layer (empty = always on).
  final String configKey;
  final bool alwaysEnabled;
  final bool androidCompatible;

  const SecurityLayer({
    required this.layerIndex,
    required this.id,
    required this.name,
    required this.description,
    required this.details,
    required this.icon,
    required this.color,
    this.configKey = '',
    this.alwaysEnabled = false,
    this.androidCompatible = true,
  });

  static const all = [
    SecurityLayer(
      layerIndex: 1,
      id: 'command_guardian',
      name: 'Command Guardian',
      description: 'Blocks 50+ dangerous shell patterns',
      details:
          'Regex-based filter on every tool invocation. Blocks rm -rf, curl pipe sh, '
          'base64 decode chains, reverse shells, and other known attack patterns.',
      icon: Icons.shield,
      color: Color(0xFFEF4444),
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 2,
      id: 'rbac',
      name: 'RBAC Policy',
      description: 'Deny-first role-based access control',
      details:
          'Every action requires explicit permission grant. No implicit allow. '
          'Policy config at permissions.* in ironclaw.yaml.',
      icon: Icons.admin_panel_settings,
      color: Color(0xFFDC2626),
      configKey: 'permissions',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 3,
      id: 'anti_stealer',
      name: 'Anti-Stealer Detection',
      description: 'Detects credential/wallet harvesting attempts',
      details:
          'Monitors tool calls for patterns matching infostealer malware: '
          'browser data access, wallet file reads, credential database queries.',
      icon: Icons.no_encryption,
      color: Color(0xFFF97316),
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 4,
      id: 'ssrf_guard',
      name: 'SSRF Guard',
      description: 'Blocks Server-Side Request Forgery',
      details:
          'Validates all outbound URLs. Blocks requests to RFC-1918 private ranges, '
          'link-local (169.254.x.x), loopback, and cloud metadata endpoints '
          '(169.254.169.254, fd00:ec2::254).',
      icon: Icons.block,
      color: Color(0xFFEAB308),
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 5,
      id: 'dlp',
      name: 'DLP Engine',
      description: 'Data loss prevention — redacts secrets in output',
      details:
          'Scans all LLM outputs and tool results for PII patterns: credit cards, '
          'SSNs, API keys, private keys, email addresses, phone numbers.',
      icon: Icons.security,
      color: Color(0xFF8B5CF6),
      configKey: 'security.dlp',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 6,
      id: 'audit_log',
      name: 'Audit Log',
      description: 'Tamper-evident, append-only event log',
      details:
          'Every agent action, tool call, and security event is logged with '
          'timestamp, session ID, and result. View with `ironclaw audit`.',
      icon: Icons.history,
      color: Color(0xFF0EA5E9),
      configKey: 'audit',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 7,
      id: 'rate_limiting',
      name: 'Rate Limiting',
      description: 'Per-channel and per-tool request throttling',
      details:
          'Token-bucket rate limiter applied at both channel ingress and per-tool '
          'execution. Prevents DoS and runaway agent loops.',
      icon: Icons.speed,
      color: Color(0xFF22C55E),
      configKey: 'rate_limit',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 8,
      id: 'input_sanitization',
      name: 'Input Sanitization',
      description: 'Sanitizes all user input before agent processing',
      details:
          'Strips null bytes, control characters, and oversized payloads. '
          'Enforces max token limits per channel type.',
      icon: Icons.cleaning_services,
      color: Color(0xFF06B6D4),
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 9,
      id: 'sandbox',
      name: 'Sandbox Isolation',
      description: 'Android: proot isolation (Docker not available)',
      details:
          'Tool execution is isolated via sandbox backend. Docker is the default '
          'but Android uses "native" mode — proot provides the isolation boundary. '
          'Config: sandbox.backend = "native" in ironclaw.yaml.',
      icon: Icons.lock_outline,
      color: Color(0xFF64748B),
      configKey: 'sandbox.backend',
      androidCompatible: true,
    ),
    SecurityLayer(
      layerIndex: 10,
      id: 'session_auth',
      name: 'Session Auth',
      description: 'HMAC-SHA256 session tokens for Web UI',
      details:
          'Web UI access requires a session token generated at startup and printed '
          'to stdout. Token is passed as URL fragment (#token=...) and verified '
          'via X-IronClaw-Session header on every request.',
      icon: Icons.vpn_key,
      color: Color(0xFFD97706),
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 11,
      id: 'memory_encryption',
      name: 'Memory Encryption',
      description: 'AES-256-GCM encrypted SQLite memory store',
      details:
          'Agent memory (conversation history, learned facts) is stored in an '
          'encrypted SQLite database. Config: memory.backend = "encrypted_sqlite".',
      icon: Icons.storage,
      color: Color(0xFF4F46E5),
      configKey: 'memory.backend',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 12,
      id: 'skill_verification',
      name: 'Skill Verification',
      description: 'Ed25519 + SHA-256 skill signature checks',
      details:
          'Every skill is verified with Ed25519 digital signatures and SHA-256 '
          'content hashes before execution. Config: skills.require_signatures = true.',
      icon: Icons.verified,
      color: Color(0xFF059669),
      configKey: 'skills.require_signatures',
      alwaysEnabled: true,
    ),
    SecurityLayer(
      layerIndex: 13,
      id: 'credential_redaction',
      name: 'Credential Redaction',
      description: 'Strips secrets from all outbound data',
      details:
          'Scans outbound tool calls and LLM prompts for API keys, tokens, '
          'passwords, and other credentials. Replaces with [REDACTED].',
      icon: Icons.visibility_off,
      color: Color(0xFF7C3AED),
      alwaysEnabled: true,
    ),
  ];
}
