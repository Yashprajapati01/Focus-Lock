import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAuthenticated;

  const User({
    this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAuthenticated,
  });

  const User.unauthenticated()
    : id = null,
      email = null,
      displayName = null,
      photoUrl = null,
      isAuthenticated = false;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAuthenticated,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    isAuthenticated,
  ];
}
