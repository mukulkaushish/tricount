import 'package:flutter_test/flutter_test.dart';

import 'package:tricount/core/network/network.dart';

void main() {
  group('JsonParser.extractByKeyPath', () {
    test('extracts nested map values', () {
      final value = JsonParser.extractByKeyPath(
        <String, dynamic>{
          'data': <String, dynamic>{
            'user': <String, dynamic>{'id': 'user-1'},
          },
        },
        'data.user.id',
      );

      expect(value, 'user-1');
    });

    test('extracts list values by index', () {
      final value = JsonParser.extractByKeyPath(
        <String, dynamic>{
          'data': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'id': 'first'},
              <String, dynamic>{'id': 'second'},
            ],
          },
        },
        'data.items.1.id',
      );

      expect(value, 'second');
    });

    test('throws for missing keyPath segments', () {
      expect(
        () => JsonParser.extractByKeyPath(
          <String, dynamic>{'data': <String, dynamic>{}},
          'data.user.id',
        ),
        throwsA(isA<DataMismatchException>()),
      );
    });
  });
}
