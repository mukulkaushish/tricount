import 'package:dio/dio.dart';
import 'package:tricount/core/security/token_provider.dart';

/// Attaches Bearer tokens and handles 401 token refresh.
///
/// Uses QueuedInterceptorsWrapper so that concurrent requests that
/// trigger a 401 are queued — only one refresh occurs, and all waiting
/// requests are retried with the new token.
///
/// Refresh logic lives in the onRefreshToken callback, which is
/// provided by the DI layer (injection_container.dart). The interceptor
/// itself stays infrastructure-agnostic.
///
/// If the refresh fails, tokens are cleared and the 401 is propagated.
final class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required final TokenProvider tokenProvider,
    required final Future<bool> Function() onRefreshToken,
    required final Dio dio,
  }) : _tokenProvider = tokenProvider,
       _onRefreshToken = onRefreshToken,
       _dio = dio;

  final TokenProvider _tokenProvider;
  final Future<bool> Function() _onRefreshToken;

  /// The main Dio instance — used to retry the original request after
  /// a successful token refresh.
  final Dio _dio;

  @override
  void onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) {
    final token = _tokenProvider.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    final DioException err,
    final ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh once per request — skip if already a retry.
    final isRetry = err.requestOptions.extra['isRetry'] == true;
    if (err.response?.statusCode == 401 && !isRetry) {
      final refreshed = await _onRefreshToken();
      if (refreshed) {
        // Retry the original request with the new token attached.
        final opts = err.requestOptions
          ..extra['isRetry'] = true
          ..headers['Authorization'] = 'Bearer ${_tokenProvider.accessToken}';
        try {
          final response = await _dio.fetch<dynamic>(opts);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else {
        // Refresh failed — clear tokens so the app can redirect to login.
        await _tokenProvider.clearTokens();
      }
    }
    return handler.next(err);
  }
}
