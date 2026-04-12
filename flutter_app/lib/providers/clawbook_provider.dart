import 'package:flutter/foundation.dart';
import '../models/clawbook.dart';
import '../services/clawbook_service.dart';

class ClawbookProvider extends ChangeNotifier {
  final _service = ClawbookService();

  ClawbookConfig _config = const ClawbookConfig();
  List<ClawbookPost> _feed = [];
  List<ClawbookPr> _prs = [];
  bool _loadingFeed = false;
  bool _loadingPrs = false;
  bool _online = false;
  String? _feedError;
  String? _prError;

  ClawbookConfig get config => _config;
  List<ClawbookPost> get feed => _feed;
  List<ClawbookPr> get prs => _prs;
  bool get loadingFeed => _loadingFeed;
  bool get loadingPrs => _loadingPrs;
  bool get isConfigured => _config.isConfigured;
  bool get isOnline => _online;
  String? get feedError => _feedError;
  String? get prError => _prError;

  Future<void> init() async {
    _config = await _service.loadConfig();
    notifyListeners();
    if (_config.isConfigured) {
      await Future.wait([loadFeed(), loadPrs()]);
    }
  }

  Future<void> saveConfig(ClawbookConfig config) async {
    await _service.saveConfig(config);
    _config = config;
    _online = false;
    _feed = [];
    _prs = [];
    notifyListeners();
    if (config.isConfigured) {
      await Future.wait([loadFeed(), loadPrs()]);
    }
  }

  Future<void> loadFeed({String sort = 'hot', String? submolt}) async {
    _loadingFeed = true;
    _feedError = null;
    notifyListeners();
    try {
      _feed = await _service.getFeed(
        sort: sort,
        submolt: submolt,
        config: _config,
      );
      _online = true;
    } on ClawbookException catch (e) {
      _feedError = e.message;
      _online = false;
    } finally {
      _loadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> loadPrs({String? status}) async {
    _loadingPrs = true;
    _prError = null;
    notifyListeners();
    try {
      _prs = await _service.listPrs(status: status, config: _config);
    } on ClawbookException catch (e) {
      _prError = e.message;
    } finally {
      _loadingPrs = false;
      notifyListeners();
    }
  }

  Future<ClawbookPr?> submitPr({
    required String title,
    required String description,
  }) async {
    try {
      final pr = await _service.submitPr(
        title: title,
        description: description,
        config: _config,
      );
      _prs = [pr, ..._prs];
      notifyListeners();
      return pr;
    } on ClawbookException {
      return null;
    }
  }

  Future<bool> approvePr(String prId, {String comment = 'LGTM!'}) async {
    try {
      final pr = await _service.addReview(
        prId: prId,
        status: 'approved',
        comment: comment,
        config: _config,
      );
      _replacePr(pr);
      return true;
    } on ClawbookException {
      return false;
    }
  }

  Future<bool> requestChanges(String prId, String comment) async {
    try {
      final pr = await _service.addReview(
        prId: prId,
        status: 'requested_changes',
        comment: comment,
        config: _config,
      );
      _replacePr(pr);
      return true;
    } on ClawbookException {
      return false;
    }
  }

  Future<ClawbookPost?> createPost({
    required String submolt,
    required String title,
    String? content,
  }) async {
    try {
      final post = await _service.createPost(
        submolt: submolt,
        title: title,
        content: content,
        config: _config,
      );
      _feed = [post, ..._feed];
      notifyListeners();
      return post;
    } on ClawbookException {
      return null;
    }
  }

  Future<String?> joinClawbook(String name) async {
    try {
      final publicKey = 'ironclaw-$name-${DateTime.now().millisecondsSinceEpoch}';
      final data = await _service.registerAgent(
        name: name,
        publicKey: publicKey,
        displayName: 'IronClaw/$name',
        description: 'IronClaw AI agent running on Android',
        config: _config,
      );
      final id = (data['agent'] as Map?)?['id'] as String? ??
          data['id'] as String? ?? '';
      final updated = _config.copyWith(agentId: id, agentName: name);
      await saveConfig(updated);
      return null; // no error
    } on ClawbookException catch (e) {
      return e.message;
    }
  }

  void _replacePr(ClawbookPr updated) {
    _prs = _prs.map((p) => p.id == updated.id ? updated : p).toList();
    notifyListeners();
  }
}
