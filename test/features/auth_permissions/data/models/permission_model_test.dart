import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/data/models/permission_model.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';

void main() {
  const tPermissionModel = PermissionModel(
    type: PermissionType.notification,
    status: PermissionStatus.granted,
    title: 'Notifications',
    description: 'Allow notifications',
    icon: Icons.notifications,
  );

  final tPermissionJson = {
    'type': 'PermissionType.notification',
    'status': 'PermissionStatus.granted',
    'title': 'Notifications',
    'description': 'Allow notifications',
    'iconCodePoint': Icons.notifications.codePoint,
    'iconFontFamily': Icons.notifications.fontFamily,
    'iconFontPackage': Icons.notifications.fontPackage,
  };

  group('PermissionModel', () {
    test('should be a subclass of Permission entity', () {
      expect(tPermissionModel, isA<Permission>());
    });

    group('fromJson', () {
      test('should return a valid PermissionModel from JSON', () {
        // act
        final result = PermissionModel.fromJson(tPermissionJson);

        // assert
        expect(result.type, equals(tPermissionModel.type));
        expect(result.status, equals(tPermissionModel.status));
        expect(result.title, equals(tPermissionModel.title));
        expect(result.description, equals(tPermissionModel.description));
        expect(result.icon.codePoint, equals(tPermissionModel.icon.codePoint));
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tPermissionModel.toJson();

        // assert
        expect(result['type'], equals(tPermissionJson['type']));
        expect(result['status'], equals(tPermissionJson['status']));
        expect(result['title'], equals(tPermissionJson['title']));
        expect(result['description'], equals(tPermissionJson['description']));
        expect(
          result['iconCodePoint'],
          equals(tPermissionJson['iconCodePoint']),
        );
      });
    });

    group('fromEntity', () {
      test('should create PermissionModel from Permission entity', () {
        // arrange
        const permission = Permission(
          type: PermissionType.notification,
          status: PermissionStatus.granted,
          title: 'Notifications',
          description: 'Allow notifications',
          icon: Icons.notifications,
        );

        // act
        final result = PermissionModel.fromEntity(permission);

        // assert
        expect(result.type, equals(permission.type));
        expect(result.status, equals(permission.status));
        expect(result.title, equals(permission.title));
        expect(result.description, equals(permission.description));
        expect(result.icon, equals(permission.icon));
      });
    });

    group('initial', () {
      test('should create initial permission with pending status', () {
        // act
        final result = PermissionModel.initial(PermissionType.notification);

        // assert
        expect(result.type, equals(PermissionType.notification));
        expect(result.status, equals(PermissionStatus.pending));
        expect(result.title, equals(PermissionType.notification.displayName));
        expect(
          result.description,
          equals(PermissionType.notification.description),
        );
        expect(result.icon, equals(PermissionType.notification.icon));
      });
    });
  });
}
