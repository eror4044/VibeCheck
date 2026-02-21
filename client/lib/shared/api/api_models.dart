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


class MediaItemDto {
  const MediaItemDto({
    required this.id,
    required this.mediaType,
    required this.url,
    required this.position,
  });

  final String id;
  final String mediaType;
  final String url;
  final int position;

  static MediaItemDto fromJson(Map<String, dynamic> json) {
    return MediaItemDto(
      id: json['id'] as String,
      mediaType: json['media_type'] as String,
      url: json['url'] as String,
      position: (json['position'] as num).toInt(),
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
    this.media = const [],
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
  final List<MediaItemDto> media;

  static FeedIdeaDto fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    final mediaList = json['media'];
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
      media: mediaList is List
          ? mediaList.map((e) => MediaItemDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}


class MyIdeaDto {
  const MyIdeaDto({
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
    required this.status,
    required this.createdAt,
    this.media = const [],
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
  final String status;
  final String createdAt;
  final List<MediaItemDto> media;

  static MyIdeaDto fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    final mediaList = json['media'];
    return MyIdeaDto(
      id: json['id'] as String,
      title: json['title'] as String,
      shortPitch: json['short_pitch'] as String,
      category: json['category'] as String,
      tags: tags is List ? tags.cast<String>() : null,
      mediaUrl: (json['media_url'] ?? '').toString(),
      oneLiner: (json['one_liner'] ?? '').toString(),
      problem: json['problem']?.toString(),
      solution: json['solution']?.toString(),
      audience: json['audience']?.toString(),
      differentiator: json['differentiator']?.toString(),
      stage: (json['stage'] ?? 'idea').toString(),
      links: json['links'] is Map<String, dynamic> ? (json['links'] as Map<String, dynamic>) : null,
      status: (json['status'] ?? 'draft').toString(),
      createdAt: json['created_at'] as String,
      media: mediaList is List
          ? mediaList.map((e) => MediaItemDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}


class CategoryStatDto {
  const CategoryStatDto({
    required this.category,
    required this.total,
    required this.vibes,
    required this.noVibes,
    required this.vibeRate,
  });

  final String category;
  final int total;
  final int vibes;
  final int noVibes;
  final double vibeRate;

  static CategoryStatDto fromJson(Map<String, dynamic> json) {
    return CategoryStatDto(
      category: json['category'] as String,
      total: (json['total'] as num).toInt(),
      vibes: (json['vibes'] as num).toInt(),
      noVibes: (json['no_vibes'] as num).toInt(),
      vibeRate: (json['vibe_rate'] as num).toDouble(),
    );
  }
}


class UserStatsDto {
  const UserStatsDto({
    required this.totalSwipes,
    required this.totalVibes,
    required this.totalNoVibes,
    required this.vibeRate,
    required this.byCategory,
  });

  final int totalSwipes;
  final int totalVibes;
  final int totalNoVibes;
  final double vibeRate;
  final List<CategoryStatDto> byCategory;

  static UserStatsDto fromJson(Map<String, dynamic> json) {
    final cats = json['by_category'];
    return UserStatsDto(
      totalSwipes: (json['total_swipes'] as num).toInt(),
      totalVibes: (json['total_vibes'] as num).toInt(),
      totalNoVibes: (json['total_no_vibes'] as num).toInt(),
      vibeRate: (json['vibe_rate'] as num).toDouble(),
      byCategory: cats is List
          ? cats.map((e) => CategoryStatDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}


class IdeaStatDto {
  const IdeaStatDto({
    required this.ideaId,
    required this.title,
    required this.totalViews,
    required this.totalVibes,
    required this.totalNoVibes,
    required this.vibeRate,
  });

  final String ideaId;
  final String title;
  final int totalViews;
  final int totalVibes;
  final int totalNoVibes;
  final double vibeRate;

  static IdeaStatDto fromJson(Map<String, dynamic> json) {
    return IdeaStatDto(
      ideaId: json['idea_id'] as String,
      title: json['title'] as String,
      totalViews: (json['total_views'] as num).toInt(),
      totalVibes: (json['total_vibes'] as num).toInt(),
      totalNoVibes: (json['total_no_vibes'] as num).toInt(),
      vibeRate: (json['vibe_rate'] as num).toDouble(),
    );
  }
}


class MyIdeasStatsDto {
  const MyIdeasStatsDto({
    required this.ideas,
    required this.totalViews,
    required this.totalVibes,
  });

  final List<IdeaStatDto> ideas;
  final int totalViews;
  final int totalVibes;

  static MyIdeasStatsDto fromJson(Map<String, dynamic> json) {
    final ideas = json['ideas'];
    return MyIdeasStatsDto(
      ideas: ideas is List
          ? ideas.map((e) => IdeaStatDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      totalViews: (json['total_views'] as num).toInt(),
      totalVibes: (json['total_vibes'] as num).toInt(),
    );
  }
}
