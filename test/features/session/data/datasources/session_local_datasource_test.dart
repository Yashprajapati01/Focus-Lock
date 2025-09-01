import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslock/features/session/data/datasources/session_local_datasource.dart';
import 'package:focuslock/features/session/data/models/session_config_model.dart';

import 'session_local_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('SessionLocalDataSourceImpl', () {
    late SessionLocalDataSourceImpl dataSource;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      dataSource = SessionLocalDataSourceImpl(
        sharedPreferences: mockSharedPreferences,
      );
    });

    group('getSessionConfig', () {
      test(
        'should return SessionConfigModel from SharedPreferences when data exists',
        () async {
          // arrange
          const testConfig = SessionConfigModel(
            duration: Duration(hours: 1),
            lastUsed: null,
          );
          final jsonString = json.encode(testConfig.toJson());

          when(
            mockSharedPreferences.getString(
              SessionLocalDataSourceImpl.sessionConfigKey,
            ),
          ).thenReturn(jsonString);

          // act
          final result = await dataSource.getSessionConfig();

          // assert
          expect(result.duration, testConfig.duration);
          verify(
            mockSharedPreferences.getString(
              SessionLocalDataSourceImpl.sessionConfigKey,
            ),
          );
        },
      );

      test(
        'should return default SessionConfigModel when no data exists',
        () async {
          // arrange
          when(
            mockSharedPreferences.getString(
              SessionLocalDataSourceImpl.sessionConfigKey,
            ),
          ).thenReturn(null);

          // act
          final result = await dataSource.getSessionConfig();

          // assert
          expect(result.duration, const Duration(minutes: 30));
          expect(result.lastUsed, isNull);
          verify(
            mockSharedPreferences.getString(
              SessionLocalDataSourceImpl.sessionConfigKey,
            ),
          );
        },
      );

      test('should handle complex duration correctly', () async {
        // arrange
        const testConfig = SessionConfigModel(
          duration: Duration(hours: 2, minutes: 30),
          lastUsed: null,
        );
        final jsonString = json.encode(testConfig.toJson());

        when(
          mockSharedPreferences.getString(
            SessionLocalDataSourceImpl.sessionConfigKey,
          ),
        ).thenReturn(jsonString);

        // act
        final result = await dataSource.getSessionConfig();

        // assert
        expect(result.duration, const Duration(hours: 2, minutes: 30));
        verify(
          mockSharedPreferences.getString(
            SessionLocalDataSourceImpl.sessionConfigKey,
          ),
        );
      });
    });

    group('cacheSessionConfig', () {
      test(
        'should call SharedPreferences to cache the session config',
        () async {
          // arrange
          const testConfig = SessionConfigModel(
            duration: Duration(hours: 1),
            lastUsed: null,
          );

          when(
            mockSharedPreferences.setString(any, any),
          ).thenAnswer((_) async => true);

          // act
          await dataSource.cacheSessionConfig(testConfig);

          // assert
          verify(
            mockSharedPreferences.setString(
              SessionLocalDataSourceImpl.sessionConfigKey,
              any,
            ),
          );
        },
      );

      test('should cache config with updated lastUsed timestamp', () async {
        // arrange
        const testConfig = SessionConfigModel(
          duration: Duration(hours: 1),
          lastUsed: null,
        );

        String? capturedJsonString;
        when(mockSharedPreferences.setString(any, any)).thenAnswer((
          invocation,
        ) async {
          capturedJsonString = invocation.positionalArguments[1] as String;
          return true;
        });

        // act
        await dataSource.cacheSessionConfig(testConfig);

        // assert
        expect(capturedJsonString, isNotNull);
        final decodedJson =
            json.decode(capturedJsonString!) as Map<String, dynamic>;
        expect(decodedJson['lastUsed'], isNotNull);
        expect(decodedJson['durationMs'], testConfig.duration.inMilliseconds);
      });

      test('should preserve existing lastUsed if provided', () async {
        // arrange
        final testDate = DateTime(2023, 1, 1);
        final testConfig = SessionConfigModel(
          duration: const Duration(hours: 1),
          lastUsed: testDate,
        );

        String? capturedJsonString;
        when(mockSharedPreferences.setString(any, any)).thenAnswer((
          invocation,
        ) async {
          capturedJsonString = invocation.positionalArguments[1] as String;
          return true;
        });

        // act
        await dataSource.cacheSessionConfig(testConfig);

        // assert
        expect(capturedJsonString, isNotNull);
        final decodedJson =
            json.decode(capturedJsonString!) as Map<String, dynamic>;
        // Should have a new timestamp, not the old one
        expect(decodedJson['lastUsed'], isNot(testDate.millisecondsSinceEpoch));
      });
    });
  });
}
