import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../storage/token_store.dart';
import 'api_models.dart';


final tokenStoreProvider = Provider<TokenStore>((ref) {
  return SharedPrefsTokenStore();
});


final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStoreProvider).getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});


final apiProvider = Provider<VibeCheckApi>((ref) {
  return VibeCheckApi(ref.read(dioProvider));
});


class VibeCheckApi {
  VibeCheckApi(this._dio);

  final Dio _dio;

  // ── Auth ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginWithGoogleIdToken({required String idToken}) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'provider': 'google',
        'id_token': idToken,
      },
    );
    return resp.data ?? <String, dynamic>{};
  }

  // ── Profile ───────────────────────────────────────────────────

  Future<MeDto> getMe() async {
    final resp = await _dio.get<Map<String, dynamic>>('/me');
    return MeDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<MeDto> putInterests(Map<String, dynamic>? interests) async {
    final resp = await _dio.put<Map<String, dynamic>>(
      '/me/interests',
      data: {'interests': interests},
    );
    return MeDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<MeDto> putProfile({String? displayName, String? about, String? avatarUrl}) async {
    final resp = await _dio.put<Map<String, dynamic>>(
      '/me/profile',
      data: {
        'display_name': displayName,
        'about': about,
        'avatar_url': avatarUrl,
      },
    );
    return MeDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<Map<String, dynamic>> createAvatarUploadUrl({required String contentType}) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/me/avatar/upload-url',
      data: {'content_type': contentType},
    );
    return resp.data ?? <String, dynamic>{};
  }

  Future<void> uploadToPresignedUrl({required String uploadUrl, required List<int> bytes, required Map<String, dynamic> headers}) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: headers,
      ),
    );
    await dio.put<void>(uploadUrl, data: Stream<List<int>>.value(bytes), options: Options(contentType: headers['Content-Type']?.toString()));
  }

  // ── Feed ──────────────────────────────────────────────────────

  Future<FeedIdeaDto?> getNextIdea() async {
    final resp = await _dio.get('/feed/next');
    final data = resp.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) return FeedIdeaDto.fromJson(data);
    return null;
  }

  Future<void> createSwipe({required String ideaId, required String direction, int? decisionTimeMs}) async {
    await _dio.post<void>(
      '/swipes',
      data: {
        'idea_id': ideaId,
        'direction': direction,
        'decision_time_ms': decisionTimeMs,
      },
    );
  }

  // ── My Ideas ──────────────────────────────────────────────────

  Future<List<MyIdeaDto>> listMyIdeas() async {
    final resp = await _dio.get<List<dynamic>>('/me/ideas');
    final data = resp.data ?? [];
    return data.map((e) => MyIdeaDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MyIdeaDto> createMyIdea(Map<String, dynamic> body) async {
    final resp = await _dio.post<Map<String, dynamic>>('/me/ideas', data: body);
    return MyIdeaDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<MyIdeaDto> updateMyIdea(String ideaId, Map<String, dynamic> body) async {
    final resp = await _dio.put<Map<String, dynamic>>('/me/ideas/$ideaId', data: body);
    return MyIdeaDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<MyIdeaDto> getMyIdea(String ideaId) async {
    final resp = await _dio.get<Map<String, dynamic>>('/me/ideas/$ideaId');
    return MyIdeaDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<void> deleteMyIdea(String ideaId) async {
    await _dio.delete<void>('/me/ideas/$ideaId');
  }

  Future<MyIdeaDto> publishMyIdea(String ideaId) async {
    final resp = await _dio.post<Map<String, dynamic>>('/me/ideas/$ideaId/publish');
    return MyIdeaDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<Map<String, dynamic>> createIdeaMediaUploadUrl({
    required String ideaId,
    required String contentType,
    required String mediaType,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/me/ideas/$ideaId/media/upload-url',
      data: {'content_type': contentType, 'media_type': mediaType},
    );
    return resp.data ?? <String, dynamic>{};
  }

  Future<MediaItemDto> registerIdeaMedia({
    required String ideaId,
    required String s3Key,
    required String mediaType,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/me/ideas/$ideaId/media',
      data: {'s3_key': s3Key, 'media_type': mediaType},
    );
    return MediaItemDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<void> deleteIdeaMedia({required String ideaId, required String mediaId}) async {
    await _dio.delete<void>('/me/ideas/$ideaId/media/$mediaId');
  }

  // ── Stats ─────────────────────────────────────────────────────

  Future<UserStatsDto> getUserStats() async {
    final resp = await _dio.get<Map<String, dynamic>>('/stats/me');
    return UserStatsDto.fromJson(resp.data ?? <String, dynamic>{});
  }

  Future<MyIdeasStatsDto> getMyIdeasStats() async {
    final resp = await _dio.get<Map<String, dynamic>>('/stats/my-ideas');
    return MyIdeasStatsDto.fromJson(resp.data ?? <String, dynamic>{});
  }
}
