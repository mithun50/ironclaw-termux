/// Clawbook data models — AI agent social network.
/// Mirrors https://github.com/oneaiguru/clawbook src/types/index.ts
library;

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class ClawbookConfig {
  final String apiUrl;
  final String agentKey;
  final String agentId;
  final String agentName;

  const ClawbookConfig({
    this.apiUrl = 'https://api.clawbook.dev',
    this.agentKey = '',
    this.agentId = '',
    this.agentName = '',
  });

  bool get isConfigured => agentKey.isNotEmpty;

  ClawbookConfig copyWith({
    String? apiUrl,
    String? agentKey,
    String? agentId,
    String? agentName,
  }) =>
      ClawbookConfig(
        apiUrl: apiUrl ?? this.apiUrl,
        agentKey: agentKey ?? this.agentKey,
        agentId: agentId ?? this.agentId,
        agentName: agentName ?? this.agentName,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// POST
// ─────────────────────────────────────────────────────────────────────────────

class ClawbookPost {
  final String id;
  final String title;
  final String? content;
  final String? url;
  final String postType;
  final String submoltName;
  final String authorId;
  final int score;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime createdAt;

  const ClawbookPost({
    required this.id,
    required this.title,
    this.content,
    this.url,
    this.postType = 'text',
    required this.submoltName,
    required this.authorId,
    this.score = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    required this.createdAt,
  });

  factory ClawbookPost.fromJson(Map<String, dynamic> j) => ClawbookPost(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        content: j['content'] as String?,
        url: j['url'] as String?,
        postType: j['postType'] as String? ?? 'text',
        submoltName: j['submoltName'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        upvotes: (j['upvotes'] as num?)?.toInt() ?? 0,
        downvotes: (j['downvotes'] as num?)?.toInt() ?? 0,
        commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  String get shortId => id.length >= 8 ? id.substring(0, 8) : id;
  String get shortAuthor =>
      authorId.length >= 8 ? authorId.substring(0, 8) : authorId;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULL REQUEST
// ─────────────────────────────────────────────────────────────────────────────

enum ClawbookPrStatus {
  draft,
  pending,
  review,
  approved,
  rejected,
  merged,
  closed;

  static ClawbookPrStatus fromString(String s) =>
      ClawbookPrStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ClawbookPrStatus.pending,
      );

  String get label => switch (this) {
        ClawbookPrStatus.draft => 'Draft',
        ClawbookPrStatus.pending => 'Pending',
        ClawbookPrStatus.review => 'In Review',
        ClawbookPrStatus.approved => 'Approved',
        ClawbookPrStatus.rejected => 'Rejected',
        ClawbookPrStatus.merged => 'Merged',
        ClawbookPrStatus.closed => 'Closed',
      };
}

class ClawbookPrReview {
  final String id;
  final String reviewerId;
  final String status; // 'approved' | 'requested_changes' | 'commented'
  final String? comment;
  final DateTime createdAt;

  const ClawbookPrReview({
    required this.id,
    required this.reviewerId,
    required this.status,
    this.comment,
    required this.createdAt,
  });

  factory ClawbookPrReview.fromJson(Map<String, dynamic> j) =>
      ClawbookPrReview(
        id: j['id'] as String? ?? '',
        reviewerId: j['reviewerId'] as String? ?? '',
        status: j['status'] as String? ?? '',
        comment: j['comment'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  String get shortReviewer =>
      reviewerId.length >= 8 ? reviewerId.substring(0, 8) : reviewerId;
}

class ClawbookPr {
  final String id;
  final int prNumber;
  final String title;
  final String description;
  final String prType;
  final ClawbookPrStatus status;
  final String authorId;
  final String baseBranch;
  final String headBranch;
  final int additions;
  final int deletions;
  final int changedFiles;
  final List<ClawbookPrReview> reviews;
  final DateTime createdAt;
  final DateTime? mergedAt;

  const ClawbookPr({
    required this.id,
    required this.prNumber,
    required this.title,
    required this.description,
    this.prType = 'feature',
    required this.status,
    required this.authorId,
    this.baseBranch = 'main',
    this.headBranch = '',
    this.additions = 0,
    this.deletions = 0,
    this.changedFiles = 0,
    this.reviews = const [],
    required this.createdAt,
    this.mergedAt,
  });

  factory ClawbookPr.fromJson(Map<String, dynamic> j) => ClawbookPr(
        id: j['id'] as String? ?? '',
        prNumber: (j['prNumber'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        prType: j['prType'] as String? ?? 'feature',
        status: ClawbookPrStatus.fromString(j['status'] as String? ?? ''),
        authorId: j['authorId'] as String? ?? '',
        baseBranch: j['baseBranch'] as String? ?? 'main',
        headBranch: j['headBranch'] as String? ?? '',
        additions: (j['additions'] as num?)?.toInt() ?? 0,
        deletions: (j['deletions'] as num?)?.toInt() ?? 0,
        changedFiles: (j['changedFiles'] as num?)?.toInt() ?? 0,
        reviews: (j['reviews'] as List<dynamic>?)
                ?.map((r) =>
                    ClawbookPrReview.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        mergedAt: j['mergedAt'] != null
            ? DateTime.tryParse(j['mergedAt'].toString())
            : null,
      );

  String get shortId => id.length >= 8 ? id.substring(0, 8) : id;
  String get shortAuthor =>
      authorId.length >= 8 ? authorId.substring(0, 8) : authorId;

  bool get hasApproval => reviews.any((r) => r.status == 'approved');
  bool get hasRequestedChanges =>
      reviews.any((r) => r.status == 'requested_changes');
}
