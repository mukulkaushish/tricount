/// Abstract interface for key-value secure storage.
///
/// The default implementation in production uses `flutter_secure_storage`.
/// Tests can inject a simple in-memory adapter.
abstract interface class SecureStore {
  Future<void> write(final String key, final String value);
  Future<String?> read(final String key);
  Future<void> delete(final String key);
  Future<void> deleteAll();
}
