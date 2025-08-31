import '../../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    super.email,
    super.displayName,
    super.photoUrl,
    required super.isAuthenticated,
  });

  const UserModel.unauthenticated() : super.unauthenticated();

  factory UserModel.fromJson(DataMap json) {
    return UserModel(
      id: json['id'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAuthenticated': isAuthenticated,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      isAuthenticated: user.isAuthenticated,
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAuthenticated,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
