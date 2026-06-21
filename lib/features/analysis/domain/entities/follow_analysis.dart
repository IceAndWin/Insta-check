class AnalysisMetadata {
  final int sampled;
  final int totalAvailable;
  final bool isApproximate;

  const AnalysisMetadata({
    required this.sampled,
    this.totalAvailable = 0,
    this.isApproximate = false,
  });

  factory AnalysisMetadata.fromJson(Map<String, dynamic> json) {
    return AnalysisMetadata(
      sampled: json['sampled'] as int? ?? 300,
      totalAvailable: json['totalAvailable'] as int? ?? 0,
      isApproximate: json['isApproximate'] as bool? ?? false,
    );
  }
}

class FollowAnalysis {
  final List<Follower> notFollowingBack;
  final List<Follower> notFollowedByUser;
  final List<Follower> mutualFollowers;
  final List<Follower> newFollowers;
  final List<Follower> lostFollowers;
  final List<Follower> mostActive;
  final DateTime analyzedAt;
  final AnalysisMetadata? metadata;

  const FollowAnalysis({
    this.notFollowingBack = const [],
    this.notFollowedByUser = const [],
    this.mutualFollowers = const [],
    this.newFollowers = const [],
    this.lostFollowers = const [],
    this.mostActive = const [],
    required this.analyzedAt,
    this.metadata,
  });

  int get totalNotFollowingBack => notFollowingBack.length;
  int get totalNotFollowedByUser => notFollowedByUser.length;
  int get totalMutual => mutualFollowers.length;
  int get totalNew => newFollowers.length;
  int get totalLost => lostFollowers.length;
  int get totalActive => mostActive.length;

  Map<String, dynamic> toJson() {
    return {
      'notFollowingBack': notFollowingBack.map((e) => e.toJson()).toList(),
      'notFollowedByUser': notFollowedByUser.map((e) => e.toJson()).toList(),
      'mutualFollowers': mutualFollowers.map((e) => e.toJson()).toList(),
      'newFollowers': newFollowers.map((e) => e.toJson()).toList(),
      'lostFollowers': lostFollowers.map((e) => e.toJson()).toList(),
      'mostActive': mostActive.map((e) => e.toJson()).toList(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory FollowAnalysis.fromJson(Map<String, dynamic> json) {
    return FollowAnalysis(
      notFollowingBack: (json['notFollowingBack'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      notFollowedByUser: (json['notFollowedByUser'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      mutualFollowers: (json['mutualFollowers'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      newFollowers: (json['newFollowers'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      lostFollowers: (json['lostFollowers'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      mostActive: (json['mostActive'] as List?)?.map((e) => Follower.fromJson(e)).toList() ?? [],
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      metadata: json['metadata'] != null ? AnalysisMetadata.fromJson(json['metadata'] as Map<String, dynamic>) : null,
    );
  }
}

class Follower {
  final String username;
  final String? fullName;
  final String? profilePicUrl;
  final bool isVerified;
  final DateTime? followedAt;
  final int? recentLikes;
  final int? recentComments;

  const Follower({
    required this.username,
    this.fullName,
    this.profilePicUrl,
    this.isVerified = false,
    this.followedAt,
    this.recentLikes,
    this.recentComments,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'profilePicUrl': profilePicUrl,
      'isVerified': isVerified,
      'followedAt': followedAt?.toIso8601String(),
      'recentLikes': recentLikes,
      'recentComments': recentComments,
    };
  }

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      followedAt: json['followedAt'] != null ? DateTime.tryParse(json['followedAt'] as String) : null,
      recentLikes: json['recentLikes'] as int?,
      recentComments: json['recentComments'] as int?,
    );
  }
}
