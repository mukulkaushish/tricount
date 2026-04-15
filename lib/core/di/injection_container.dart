import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:tricount/core/constants/api_constants.dart';
import 'package:tricount/core/logging/logging.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/core/security/secure_token_provider.dart';
import 'package:tricount/core/security/token_provider.dart';
import 'package:tricount/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tricount/features/auth/data/datasources/social_auth_datasource.dart';
import 'package:tricount/features/auth/data/models/auth_token_model.dart';
import 'package:tricount/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';
import 'package:tricount/features/auth/domain/usecases/usecases.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';

/// Global service-locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies. Call once before runApp.
Future<void> configureDependencies() async {
  await _registerCore();
  _registerAuth();
}

Future<void> _registerCore() async {
  // ── Logging ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppLogger>(PrettyAppLogger.new);

  // ── Secure storage + token provider ──────────────────────────────────────
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final tokenProvider = SecureTokenProvider(storage);
  await tokenProvider.initialize();
  sl.registerSingleton<TokenProvider>(tokenProvider);

  // ── Dio ───────────────────────────────────────────────────────────────────
  // Build the Dio instance first so the refresh callback can capture it.
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: httpTimeout,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: httpTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  // Refresh callback: called by AuthInterceptor on every 401.
  // Uses the same Dio instance (marked isRetry) so it goes through the
  // LogInterceptor but skips a second refresh attempt.
  Future<bool> refreshTokenCallback() async {
    final refreshToken = tokenProvider.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await dio.post<dynamic>(
        authRefreshPath,
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'isRetry': true}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return false;
      final model = AuthTokenModel.fromJson(data);
      await tokenProvider.saveTokens(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
      );
      return true;
    } on Exception {
      return false;
    }
  }

  dio.interceptors.addAll([
    AuthInterceptor(
      tokenProvider: tokenProvider,
      onRefreshToken: refreshTokenCallback,
      dio: dio,
    ),
    if (kDebugMode)
      LogInterceptor(
        logPrint: (final o) => sl<AppLogger>().debug(o),
      ),
  ]);

  sl
    ..registerSingleton<Dio>(dio)
    ..registerLazySingleton<HttpClient>(
      () => DioHttpClient(sl<Dio>(), appLogger: sl<AppLogger>()),
    );
}

void _registerAuth() {
  sl
    ..registerLazySingleton<SocialAuthDataSource>(
      NativeSocialAuthDataSource.new,
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => DioAuthDataSource(sl<HttpClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => RemoteAuthRepository(
        sl<AuthRemoteDataSource>(),
        sl<SocialAuthDataSource>(),
      ),
    )
    ..registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()))
    ..registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()))
    ..registerLazySingleton(
      () => ForgotPasswordUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => ResetPasswordUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => RefreshTokenUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => LoginWithGoogleUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => LoginWithAppleUseCase(sl<AuthRepository>()),
    )
    ..registerFactory(
      () => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
        resetPasswordUseCase: sl<ResetPasswordUseCase>(),
        loginWithGoogleUseCase: sl<LoginWithGoogleUseCase>(),
        loginWithAppleUseCase: sl<LoginWithAppleUseCase>(),
      ),
    );
}
