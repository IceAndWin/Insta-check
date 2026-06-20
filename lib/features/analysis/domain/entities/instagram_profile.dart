class InstagramProfile {
  final String username;
  final String fullName;
  final String? biography;
  final String? profilePicUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isPrivate;
  final bool isVerified;
  final String? externalUrl;
  final String? businessCategory;
  final DateTime? lastUpdated;

  const InstagramProfile({
    required this.username,
    required this.fullName,
    this.biography,
    this.profilePicUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.isPrivate = false,
    this.isVerified = false,
    this.externalUrl,
    this.businessCategory,
    this.lastUpdated,
  });

  double get engagementRate {
    if (followersCount == 0) return 0;
    return (postsCount > 0 ? (followersCount * 0.03) : 0) / followersCount * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'biography': biography,
      'profilePicUrl': profilePicUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'externalUrl': externalUrl,
      'businessCategory': businessCategory,
    };
  }

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      username: json['username'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      biography: json['biography'] as String? ?? json['bio'] as String?,
      profilePicUrl: json['profilePicUrl'] as String? ?? json['profile_pic_url'] as String? ?? json['profile_picture'] as String?,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['postsCount'] as num?)?.toInt() ?? (json['posts_count'] as num?)?.toInt() ?? 0,
      isPrivate: json['isPrivate'] as bool? ?? json['is_private'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      externalUrl: json['externalUrl'] as String? ?? json['external_url'] as String?,
      businessCategory: json['businessCategory'] as String? ?? json['business_category'] as String?,
    );
  }
}
