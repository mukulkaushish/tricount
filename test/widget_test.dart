import 'package:flutter_test/flutter_test.dart';

import 'package:tricount/features/auth/data/models/models.dart';

void main() {
  group('Auth models', () {
    test('parses token payloads', () {
      final model = AuthTokensModel.fromJson(
        const {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
      );

      expect(model.accessToken, 'access-token');
      expect(model.refreshToken, 'refresh-token');
      expect(model.toEntity().accessToken, 'access-token');
    });

    test('parses nested me payloads', () {
      final model = AuthenticatedUserModel.fromJson(
        const {
          'user': {
            'id': 'user-1',
            'email': 'test@example.com',
            'displayName': 'Test User',
            'emailVerified': true,
            'passkeyEnabled': true,
          },
        },
      );

      final entity = model.toEntity();

      expect(entity.id, 'user-1');
      expect(entity.email, 'test@example.com');
      expect(entity.displayName, 'Test User');
      expect(entity.emailVerified, isTrue);
      expect(entity.passkeyEnabled, isTrue);
    });
  });
}
