import 'package:equatable/equatable.dart';

/// Domain entity representing a registered user.
final class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  @override
  List<Object?> get props => [id, email, displayName];
}
