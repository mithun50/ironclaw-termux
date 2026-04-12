import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clawbook.dart';

/// HTTP client for the Clawbook API.
/// https://github.com/oneaiguru/clawbook
class ClawbookService {
  static const _keyApiUrl = 'clawbook_api_url';
  static const _keyAgentKey = 'clawbook_agent_key';
  static const _keyAgentId = 'clawbook_agent_id';
  static const _keyAgentName = 'clawbook_agent_name';

  // ─────────────────────────────────────────────────────────────────────────
  // CONFIG PERSISTENCE
  // ─────────────────────────────────────────────────────────────────────────

  Future<ClawbookConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return ClawbookConfig(
      apiUrl: prefs.getString(_keyApiUrl) ?? 'https://api.clawbook.dev',
      agentKey: prefs.getString(_keyAgentKey) ?? '',
      agentId: prefs.getString(_keyAgentId) ?? '',
      agentName: prefs.getString(_keyAgentName) ?? '',
    );
  }

  Future<void> saveConfig(ClawbookConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiUrl, config.apiUrl);
    await prefs.setString(_keyAgentKey, config.agentKey);
    await prefs.setString(_keyAgentId, config.agentId);
    await prefs.setString(_keyAgentName, config.agentName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP HELPER
  // ─────────────────────────────────────────────────────────────────────────

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required ClawbookConfig config,
  }) async {
    final uri = Uri.parse('${config.apiUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (config.agentKey.isNotEmpty)
        'Authorization': 'Bearer ${config.agentKey}',
    };

    http.Response res;
    try {
      res = await switch (method) {
        'POST' => http.post(uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null),
        'PATCH' => http.patch(uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null),
        _ => http.get(uri, headers: headers),
      }.timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ClawbookException('Cannot reach Clawbook at ${config.apiUrl}: $e');
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = {'message': res.body};
    }

    if (res.statusCode >= 400) {
      final msg = (data is Map ? data['message'] ?? data['error'] : null) ??
          res.reasonPhrase ??
          'Unknown error';
      throw ClawbookException('${res.statusCode}: $msg');
    }

    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AGENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> registerAgent({
    required String name,
    required String publicKey,
    String? displayName,
    String? description,
    required ClawbookConfig config,
  }) async {
    final data = await _request(
      'POST',
      '/api/agents',
      body: {
        'name': name,
        'publicKey': publicKey,
        if (displayName != null) 'displayName': displayName,
        if (description != null) 'description': description,
      },
      config: config,
    ) as Map<String, dynamic>;
    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEED
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<ClawbookPost>> getFeed({
    String? submolt,
    String sort = 'hot',
    int limit = 20,
    required ClawbookConfig config,
  }) async {
    var path = '/api/feed?sort=$sort&limit=$limit';
    if (submolt != null && submolt.isNotEmpty) {
      path += '&submolt=${Uri.encodeComponent(submolt)}';
    }

    final data = await _request('GET', path, config: config);
    final list = (data is Map ? data['posts'] : data) as List<dynamic>? ?? [];
    return list
        .map((e) => ClawbookPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClawbookPost> createPost({
    required String submolt,
    required String title,
    String? content,
    required ClawbookConfig config,
  }) async {
    final data = await _request(
      'POST',
      '/api/posts',
      body: {
        'submolt': submolt,
        'title': title,
        'postType': 'text',
        if (content != null && content.isNotEmpty) 'content': content,
      },
      config: config,
    ) as Map<String, dynamic>;

    final post = data['post'] as Map<String, dynamic>? ?? data;
    return ClawbookPost.fromJson(post);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PULL REQUESTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<ClawbookPr>> listPrs({
    String? status,
    int limit = 30,
    required ClawbookConfig config,
  }) async {
    var path = '/api/prs?limit=$limit';
    if (status != null && status.isNotEmpty) {
      path += '&status=${Uri.encodeComponent(status)}';
    }

    final data = await _request('GET', path, config: config);
    final list = (data is Map ? data['prs'] : data) as List<dynamic>? ?? [];
    return list
        .map((e) => ClawbookPr.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClawbookPr> getPr(String id, {required ClawbookConfig config}) async {
    final data = await _request('GET', '/api/prs/$id', config: config)
        as Map<String, dynamic>;
    final pr = data['pr'] as Map<String, dynamic>? ?? data;
    return ClawbookPr.fromJson(pr);
  }

  Future<ClawbookPr> submitPr({
    required String title,
    required String description,
    List<Map<String, String>> fileChanges = const [],
    required ClawbookConfig config,
  }) async {
    final data = await _request(
      'POST',
      '/api/prs',
      body: {
        'title': title,
        'description': description,
        'fileChanges': fileChanges,
      },
      config: config,
    ) as Map<String, dynamic>;

    final pr = data['pr'] as Map<String, dynamic>? ?? data;
    return ClawbookPr.fromJson(pr);
  }

  Future<ClawbookPr> addReview({
    required String prId,
    required String status, // 'approved' | 'requested_changes' | 'commented'
    String? comment,
    required ClawbookConfig config,
  }) async {
    final data = await _request(
      'POST',
      '/api/prs/$prId/review',
      body: {
        'status': status,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      config: config,
    ) as Map<String, dynamic>;

    final pr = data['pr'] as Map<String, dynamic>? ?? data;
    return ClawbookPr.fromJson(pr);
  }

  Future<Map<String, dynamic>> canMerge(
    String prId, {
    required ClawbookConfig config,
  }) async {
    final data = await _request('GET', '/api/prs/$prId/can-merge',
        config: config) as Map<String, dynamic>;
    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTIVITY CHECK
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> ping(ClawbookConfig config) async {
    try {
      await _request('GET', '/api/feed?limit=1', config: config);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ClawbookException implements Exception {
  final String message;
  const ClawbookException(this.message);

  @override
  String toString() => message;
}
