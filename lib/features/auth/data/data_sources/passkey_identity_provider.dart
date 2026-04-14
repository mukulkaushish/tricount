import 'package:fpdart/fpdart.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'package:tricount/core/network/network.dart';

class FlutterPasskeyIdentityProvider {
  const FlutterPasskeyIdentityProvider({
    required PasskeyAuthenticator authenticator,
  }) : _authenticator = authenticator;

  final PasskeyAuthenticator _authenticator;

  Future<Either<AppException, Map<String, dynamic>>> authenticate({
    required Map<String, dynamic> options,
  }) async {
    try {
      final request = AuthenticateRequestType.fromJson(options);
      final credential = await _authenticator.authenticate(request);
      final payload = Map<String, dynamic>.from(
        credential.toJson(),
      );

      return right(payload);
    } on Object catch (error) {
      return left(
        ValidationAppException(message: error.toString()),
      );
    }
  }
}
