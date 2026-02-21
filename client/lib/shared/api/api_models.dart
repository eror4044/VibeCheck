class MeDto {
  const MeDto({
    required this.id,
    required this.authProvider,
    required this.createdAt,
    required this.interests,
    required this.displayName,
    required this.about,
    required this.avatarUrl,
  });

  final String id;
  final String authProvider;
  final String createdAt;
  final Map<String, dynamic>? interests;
  final String? displayName;
  final String? about;
  final String? avatarUrl;

  static MeDto fromJson(Map<String, dynamic> json) {
    return MeDto(
      id: json['id'] as String,
      authProvider: json['auth_provider'] as String,
      createdAt: json['created_at'] as String,
      interests: (json['interests'] as Map?)?.cast<String, dynamic>(),
      displayName: json['display_name']?.toString(),
      about: json['about']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}


class FeedIdeaDto {
  const FeedIdeaDto({
    required this.id,
    required this.title,
    required this.shortPitch,
    required this.category,
    required this.tags,
    required this.mediaUrl,
    required this.oneLiner,
    required this.problem,
    required this.solution,
    required this.audience,
    required this.differentiator,
    required this.stage,
    required this.links,
  });

  final String id;
  final String title;
  final String shortPitch;
  final String category;
  final List<String>? tags;
  final String mediaUrl;

  final String oneLiner;
  final String? problem;
  final String? solution;
  final String? audience;
  final String? differentiator;
  final String stage;
  final Map<String, dynamic>? links;

  static FeedIdeaDto fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    return FeedIdeaDto(
      id: json['id'] as String,
      title: json['title'] as String,
      shortPitch: json['short_pitch'] as String,
      category: json['category'] as String,
      tags: tags is List ? tags.cast<String>() : null,
      mediaUrl: json['media_url'] as String,
      oneLiner: (json['one_liner'] ?? json['short_pitch'] ?? '').toString(),
      problem: json['problem']?.toString(),
      solution: json['solution']?.toString(),
      audience: json['audience']?.toString(),
      differentiator: json['differentiator']?.toString(),
      stage: (json['stage'] ?? 'idea').toString(),
      links: json['links'] is Map<String, dynamic> ? (json['links'] as Map<String, dynamic>) : null,
    );
  }
}
