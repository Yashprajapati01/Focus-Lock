import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/data/models/user_model.dart';
import 'package:focuslock/features/auth/domain/entities/user.dart';

void main() {
  const tUserModel = UserModel(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isAuthenticated: true,
  );

  const tUserJson = {
    'id': 'test-id',
    'email': 'test@example.com',
    'displayName': 'Test User',
    'photoUrl': 'https://example.com/photo.jpg',
    'isAuthenticated': true,
  };

  group('UserModel', () {
    test('should be a subclass of User entity', () {
      expect(tUserModel, isA<User>());
    });

    group('fromJson', () {
      test('should return a valid UserModel from JSON', () {
        // act
        final result = UserModel.fromJson(tUserJson);

        // assert
        expect(result, equals(tUserModel));
      });

      test('should handle missing isAuthenticated field', () {
        // arrange
        final jsonWithoutAuth = Map<String, dynamic>.from(tUserJson);
        jsonWithoutAuth.remove('isAuthenticated');

        // act
        final result = UserModel.fromJson(jsonWithoutAuth);

        // assert
        expect(result.isAuthenticated, false);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tUserModel.toJson();

        // assert
        expect(result, equals(tUserJson));
      });
    });

    group('fromEntity', () {
      test('should create UserModel from User entity', () {
        // arrange
        const user = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          isAuthenticated: true,
        );

        // act
        final result = UserModel.fromEntity(user);

        // assert
        expect(result, equals(tUserModel));
      });
    });

    group('unauthenticated constructor', () {
      test('should create unauthenticated user', () {
        // act
        const result = UserModel.unauthenticated();

        // assert
        expect(result.id, isNull);
        expect(result.email, isNull);
        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.isAuthenticated, false);
      });
    });
  });
}
