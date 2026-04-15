/// Validation and convenience extensions on [String].
extension StringValidation on String {
  /// Returns true if this string is a well-formed email address.
  ///
  /// Used by auth forms (login, register, forgot-password) to avoid
  /// duplicating the regex pattern.
  bool get isValidEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(this);
}
