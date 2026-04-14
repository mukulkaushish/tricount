import 'package:dio/dio.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/network/app_exception.dart';
import 'package:tricount/core/network/json_parser.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required AuthSessionStore sessionStore,
    required String baseUrl,
  }) : _sessionStore = sessionStore,
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           sendTimeout: const Duration(seconds: 15),
           headers: const {'Content-Type': 'application/json'},
         ),
       );

  final Dio _refreshDio;
  final AuthSessionStore _sessionStore;

  Future<AuthTokens?>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final requiresAuth = requestOptions.extra['requiresAuth'] != false;
    final isRefreshRequest = requestOptions.path.endsWith('/v1/auth/refresh');

    if (!isUnauthorized || !requiresAuth || isRefreshRequest) {
      handler.next(err);
      return;
    }

    AuthTokens? refreshedTokens;
    try {
      refreshedTokens = await _refreshTokens();
    } on AppException {
      refreshedTokens = null;
    }

    if (refreshedTokens == null) {
      await _sessionStore.clearTokens();
      handler.next(err);
      return;
    }

    final retryOptions = requestOptions.copyWith(
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer ${refreshedTokens.accessToken}',
      },
    );

    try {
      final response = await _refreshDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['requiresAuth'] == false) {
      handler.next(options);
      return;
    }

    final tokens = await _sessionStore.readTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    handler.next(options);
  }

  Future<AuthTokens?> _refreshTokens() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _performRefresh();
    final tokens = await _refreshFuture;
    _refreshFuture = null;
    return tokens;
  }

  Future<AuthTokens?> _performRefresh() async {
    final tokens = await _sessionStore.readTokens();
    if (tokens == null) {
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': tokens.refreshToken},
        options: Options(extra: const {'requiresAuth': false}),
      );

      final body = response.data;
      if (body == null) {
        return null;
      }

      final refreshedTokens = AuthTokens(
        accessToken: JsonParser.parseString(body, 'accessToken'),
        refreshToken: JsonParser.parseString(body, 'refreshToken'),
      );

      await _sessionStore.saveTokens(refreshedTokens);
      return refreshedTokens;
    } on DioException catch (error) {
      throw AppException.fromDioException(error);
    }
  }
}
