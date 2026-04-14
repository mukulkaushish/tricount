import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:passkeys/authenticator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tricount/core/auth/auth.dart';
import 'package:tricount/core/env/app_environment.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/core/theme/theme.dart';
import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/features/auth/data/data.dart';
import 'package:tricount/router/router.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<SharedPreferences>()) {
    return;
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  const appAuth = FlutterAppAuth();
  final passkeyAuthenticator = PasskeyAuthenticator(debugMode: kDebugMode);

  sl
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerSingleton<FlutterSecureStorage>(secureStorage)
    ..registerSingleton<FlutterAppAuth>(appAuth)
    ..registerSingleton<PasskeyAuthenticator>(passkeyAuthenticator)
    ..registerLazySingleton<AuthSessionStore>(
      () => SecureAuthSessionStore(storage: sl()),
    )
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppEnvironment.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {'Content-Type': 'application/json'},
        ),
      ),
    )
    ..registerLazySingleton<HttpClient>(
      () => DioHttpClient(
        dio: sl(),
        authInterceptor: AuthInterceptor(
          sessionStore: sl(),
          baseUrl: AppEnvironment.baseUrl,
        ),
        enableLogging: kDebugMode,
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => DioAuthDataSource(httpClient: sl()),
    )
    ..registerLazySingleton<FlutterAppAuthIdentityProvider>(
      () => FlutterAppAuthIdentityProvider(appAuth: sl()),
    )
    ..registerLazySingleton<FlutterPasskeyIdentityProvider>(
      () => FlutterPasskeyIdentityProvider(authenticator: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => RemoteAuthRepository(
        remoteDataSource: sl(),
        oidcIdentityProvider: sl(),
        passkeyIdentityProvider: sl(),
        sessionStore: sl(),
      ),
    )
    ..registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()))
    ..registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl()))
    ..registerLazySingleton<SendPasswordResetOtpUseCase>(
      () => SendPasswordResetOtpUseCase(sl()),
    )
    ..registerLazySingleton<ResetPasswordUseCase>(
      () => ResetPasswordUseCase(sl()),
    )
    ..registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(sl()),
    )
    ..registerLazySingleton<SignInWithAppleUseCase>(
      () => SignInWithAppleUseCase(sl()),
    )
    ..registerLazySingleton<SignInWithPasskeyUseCase>(
      () => SignInWithPasskeyUseCase(sl()),
    )
    ..registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(sl()),
    )
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        sendPasswordResetOtpUseCase: sl(),
        resetPasswordUseCase: sl(),
        signInWithGoogleUseCase: sl(),
        signInWithAppleUseCase: sl(),
        signInWithPasskeyUseCase: sl(),
      ),
    )
    ..registerFactory<ThemeBloc>(
      () => ThemeBloc(
        prefs: sl(),
        platform: defaultTargetPlatform,
      ),
    )
    ..registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        sessionStore: sl(),
        getCurrentUserUseCase: sl(),
      ),
    )
    ..registerLazySingleton<AuthGuard>(
      () => AuthGuard(sessionStore: sl()),
    )
    ..registerLazySingleton<AppRouter>(
      () => AppRouter(authGuard: sl()),
    );
}
