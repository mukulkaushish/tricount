import 'package:dio/dio.dart';
import 'package:tricount/core/security/token_provider.dart';

/// Attaches the Bearer token to every outgoing request.
///
/// If no access token is stored (e.g., on the login screen) the request
/// is forwarded unchanged — the server will respond with 401.
final class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._tokenProvider);

  final TokenProvider _tokenProvider;

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
}
