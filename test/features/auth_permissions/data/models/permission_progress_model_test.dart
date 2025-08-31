import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:focuslock/features/permissions/data/models/permission_progress_model.dart';

void main() {
  const tProgressModel = PermissionProgressModel(
    totalPermissions: 4,
    grantedPermissions: 2,
    progressPercentage: 0.5,
    isComplete: false,
  );

  const tProgressJson = {
    'totalPermissions': 4,
    'grantedPermissions': 2,
    'progressPercentage': 0.5,
    'isComplete': false,
  };

  group('PermissionProgressModel', () {
    test('should be a subclass of PermissionProgress entity', () {
      expect(tProgressModel, isA<PermissionProgress>());
    });

    group('fromJson', () {
      test('should return a valid PermissionProgressModel from JSON', () {
        // act
        final result = PermissionProgressModel.fromJson(tProgressJson);

        // assert
        expect(result, equals(tProgressModel));
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        // act
        final result = tProgressModel.toJson();

        // assert
        expect(result, equals(tProgressJson));
      });
    });

    group('fromEntity', () {
      test(
        'should create PermissionProgressModel from PermissionProgress entity',
        () {
          // arrange
          const progress = PermissionProgress(
            totalPermissions: 4,
            grantedPermissions: 2,
            progressPercentage: 0.5,
            isComplete: false,
          );

          // act
          final result = PermissionProgressModel.fromEntity(progress);

          // assert
          expect(result, equals(tProgressModel));
        },
      );
    });

    group('fromGrantedCount', () {
      test('should calculate progress correctly', () {
        // act
        final result = PermissionProgressModel.fromGrantedCount(3, 4);

        // assert
        expect(result.totalPermissions, equals(4));
        expect(result.grantedPermissions, equals(3));
        expect(result.progressPercentage, equals(0.75));
        expect(result.isComplete, equals(false));
      });

      test('should mark as complete when all permissions granted', () {
        // act
        final result = PermissionProgressModel.fromGrantedCount(4, 4);

        // assert
        expect(result.isComplete, equals(true));
        expect(result.progressPercentage, equals(1.0));
      });
    });

    group('initial', () {
      test('should create initial progress with zero granted', () {
        // act
        final result = PermissionProgressModel.initial();

        // assert
        expect(result.totalPermissions, equals(4));
        expect(result.grantedPermissions, equals(0));
        expect(result.progressPercentage, equals(0.0));
        expect(result.isComplete, equals(false));
      });
    });
  });
}
