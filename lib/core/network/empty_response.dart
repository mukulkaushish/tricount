/// Typed sentinel for responses that carry no meaningful body.
///
/// Use this as the success type for DELETE, logout, and similar no-body
/// requests so callers still get a typed `Either<AppException, EmptyResponse>`.
final class EmptyResponse {
  const EmptyResponse();
}
