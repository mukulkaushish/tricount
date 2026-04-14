import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tricount/core/constants/api_constants.dart';
import 'package:tricount/core/logging/logging.dart';
import 'package:tricount/core/network/network.dart';
import 'package:tricount/core/security/token_provider.dart';
import 'package:tricount/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tricount/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:tricount/features/auth/domain/repositories/auth_repository.dart';
import 'package:tricount/features/auth/domain/usecases/usecases.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';

/// Global service-locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies.
///
/// Call `await configureDependencies()` in [main] before [runApp].
Future<void> configureDependencies() async {
  _registerCore();
  _registerAuth();
}

void _registerCore() {
  // Logging
  sl
    ..registerLazySingleton<AppLogger>(PrettyAppLogger.new)

    // Token storage (in-memory for now — swap for SecureTokenProvider in prod)
    ..registerLazySingleton<TokenProvider>(InMemoryTokenProvider.new)

    // Dio
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: httpTimeout,
          receiveTimeout: httpTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      )..interceptors.add(AuthInterceptor(sl<TokenProvider>())),
    )

    // HTTP client
    ..registerLazySingleton<HttpClient>(
      () => NetworkManager(sl<Dio>(), appLogger: sl<AppLogger>()),
    );
}

void _registerAuth() {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => DioAuthDataSource(sl<HttpClient>()),
  );

  // Repositories + use cases + BLoC
  sl
    ..registerLazySingleton<AuthRepository>(
      () => RemoteAuthRepository(sl<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()))
    ..registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()))
    ..registerLazySingleton(
      () => ForgotPasswordUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => ResetPasswordUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(() => RefreshTokenUseCase(sl<AuthRepository>()))
    ..registerLazySingleton(
      () => LoginWithGoogleUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => LoginWithAppleUseCase(sl<AuthRepository>()),
    );

  sl.registerFactory(
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
