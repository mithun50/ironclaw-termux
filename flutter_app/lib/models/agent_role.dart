import 'package:flutter/material.dart';

/// One of IronClaw's 6 built-in agent roles.
/// Source: ironclaw/src/agents/mod.rs
class AgentRole {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> capabilities;

  const AgentRole({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.capabilities,
  });

  static const researcher = AgentRole(
    id: 'researcher',
    name: 'Researcher',
    description: 'Gathers information from the web, documents, and APIs',
    icon: Icons.search,
    color: Color(0xFF0EA5E9),
    capabilities: ['web_search', 'document_read', 'api_query', 'summarize'],
  );

  static const coder = AgentRole(
    id: 'coder',
    name: 'Coder',
    description: 'Writes, refactors, debugs, and tests code',
    icon: Icons.code,
    color: Color(0xFF7C3AED),
    capabilities: ['code_generate', 'file_edit', 'shell_run', 'test_execute'],
  );

  static const reviewer = AgentRole(
    id: 'reviewer',
    name: 'Reviewer',
    description: 'Reviews work from other agents for quality and correctness',
    icon: Icons.rate_review,
    color: Color(0xFF22C55E),
    capabilities: ['code_review', 'fact_check', 'quality_assess', 'feedback'],
  );

  static const planner = AgentRole(
    id: 'planner',
    name: 'Planner',
    description: 'Decomposes goals into sub-tasks and coordinates agents',
    icon: Icons.account_tree,
    color: Color(0xFFD97706),
    capabilities: ['task_decompose', 'dag_build', 'priority_assign', 'coordinate'],
  );

  static const tester = AgentRole(
    id: 'tester',
    name: 'Tester',
    description: 'Writes and runs tests, reports coverage',
    icon: Icons.bug_report,
    color: Color(0xFFF97316),
    capabilities: ['test_write', 'test_run', 'coverage_report', 'regression_check'],
  );

  static const securityAuditor = AgentRole(
    id: 'security_auditor',
    name: 'Security Auditor',
    description: 'Audits code and configs for security vulnerabilities',
    icon: Icons.security,
    color: Color(0xFFEF4444),
    capabilities: ['vuln_scan', 'dependency_audit', 'config_review', 'threat_model'],
  );

  static const all = [researcher, coder, reviewer, planner, tester, securityAuditor];
}

/// IronClaw's 5 multi-agent coordination patterns.
/// Source: ironclaw/src/workflow/mod.rs
enum CoordinationPattern {
  sequential,
  parallel,
  debate,
  hierarchical,
  pipeline;

  /// Exact variant name used in ironclaw.yaml workflow config.
  String get configValue {
    final s = name;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class AgentCoordinationInfo {
  final CoordinationPattern pattern;
  final String name;
  final String description;
  final String useCases;
  final IconData icon;
  final Color color;

  const AgentCoordinationInfo({
    required this.pattern,
    required this.name,
    required this.description,
    required this.useCases,
    required this.icon,
    required this.color,
  });

  static const all = [
    AgentCoordinationInfo(
      pattern: CoordinationPattern.sequential,
      name: 'Sequential',
      description: 'Agents run one after another, each building on the previous output',
      useCases: 'Research → write → review pipelines',
      icon: Icons.arrow_forward,
      color: Color(0xFF0EA5E9),
    ),
    AgentCoordinationInfo(
      pattern: CoordinationPattern.parallel,
      name: 'Parallel',
      description: 'Agents run simultaneously on independent sub-tasks',
      useCases: 'Multi-file analysis, batch processing',
      icon: Icons.fork_right,
      color: Color(0xFF22C55E),
    ),
    AgentCoordinationInfo(
      pattern: CoordinationPattern.debate,
      name: 'Debate',
      description: 'Multiple agents propose solutions, then vote/merge on the best',
      useCases: 'Architecture decisions, critical code review',
      icon: Icons.people,
      color: Color(0xFF7C3AED),
    ),
    AgentCoordinationInfo(
      pattern: CoordinationPattern.hierarchical,
      name: 'Hierarchical',
      description: 'A planner agent delegates sub-tasks to specialist agents',
      useCases: 'Complex multi-step projects, software development',
      icon: Icons.account_tree,
      color: Color(0xFFD97706),
    ),
    AgentCoordinationInfo(
      pattern: CoordinationPattern.pipeline,
      name: 'Pipeline',
      description: 'Agents form a DAG where each node transforms and passes data',
      useCases: 'ETL workflows, continuous processing, CI/CD',
      icon: Icons.linear_scale,
      color: Color(0xFFF97316),
    ),
  ];
}
