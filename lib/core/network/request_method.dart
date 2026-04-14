/// HTTP verb used in [HttpClient] calls.
enum RequestMethod { get, post, put, delete, patch }

/// Extension that converts [RequestMethod] to its Dio-compatible string value.
extension RequestMethodExtension on RequestMethod {
  String get verb => switch (this) {
        RequestMethod.get => 'GET',
        RequestMethod.post => 'POST',
        RequestMethod.put => 'PUT',
        RequestMethod.delete => 'DELETE',
        RequestMethod.patch => 'PATCH',
      };
}
