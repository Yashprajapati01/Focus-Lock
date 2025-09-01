import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/data/services/device_admin_service.dart';

void main() {
  group('DeviceAdminServiceImpl', () {
    late DeviceAdminServiceImpl service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = DeviceAdminServiceImpl();
      methodCalls = [];

      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.focuslock/device_admin'),
            (MethodCall methodCall) async {
              methodCalls.add(methodCall);

              switch (methodCall.method) {
                case 'hasDeviceAdminPermission':
                  return true;
                case 'hasOverlayPermission':
                  return true;
                case 'startDeviceLock':
                  return null;
                case 'endDeviceLock':
                  return null;
                case 'requestDeviceAdminPermission':
                  return true;
                case 'requestOverlayPermission':
                  return true;
                default:
                  throw MissingPluginException();
              }
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.focuslock/device_admin'),
            null,
          );
    });

    group('hasDeviceAdminPermission', () {
      testWidgets('returns true when permission is granted', (tester) async {
        final result = await service.hasDeviceAdminPermission();

        if (Platform.isAndroid) {
          expect(result, isTrue);
          expect(methodCalls.length, equals(1));
          expect(methodCalls.first.method, equals('hasDeviceAdminPermission'));
        } else {
          // On non-Android platforms, should return false
          expect(result, isFalse);
        }
      });

      testWidgets('returns false when platform exception occurs', (
        tester,
      ) async {
        // Mock platform exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                throw PlatformException(code: 'ERROR', message: 'Test error');
              },
            );

        final result = await service.hasDeviceAdminPermission();

        expect(result, isFalse);
      });
    });

    group('hasOverlayPermission', () {
      testWidgets('returns true when permission is granted', (tester) async {
        final result = await service.hasOverlayPermission();

        if (Platform.isAndroid) {
          expect(result, isTrue);
          expect(methodCalls.length, equals(1));
          expect(methodCalls.first.method, equals('hasOverlayPermission'));
        } else {
          // On non-Android platforms, should return false
          expect(result, isFalse);
        }
      });

      testWidgets('returns false when platform exception occurs', (
        tester,
      ) async {
        // Mock platform exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                throw PlatformException(code: 'ERROR', message: 'Test error');
              },
            );

        final result = await service.hasOverlayPermission();

        expect(result, isFalse);
      });
    });

    group('startDeviceLock', () {
      testWidgets('starts device lock when permissions are granted', (
        tester,
      ) async {
        if (Platform.isAndroid) {
          await service.startDeviceLock();

          expect(methodCalls.length, equals(3));
        expect(methodCalls[0].method, equals('hasDeviceAdminPermission'));
        expect(methodCalls[1].method, equals('hasOverlayPermission'));
        expect(methodCalls[2].method, equals('startDeviceLock'));
        expect(service.isLocked, isTrue);
      });

      testWidgets('throws exception when device admin permission is missing', (
        tester,
      ) async {
        // Mock missing device admin permission
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                switch (methodCall.method) {
                  case 'hasDeviceAdminPermission':
                    return false;
                  case 'hasOverlayPermission':
                    return true;
                  default:
                    return null;
                }
              },
            );

        expect(
          () => service.startDeviceLock(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Device admin permission is required'),
            ),
          ),
        );
      });

      testWidgets('throws exception when overlay permission is missing', (
        tester,
      ) async {
        // Mock missing overlay permission
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                switch (methodCall.method) {
                  case 'hasDeviceAdminPermission':
                    return true;
                  case 'hasOverlayPermission':
                    return false;
                  default:
                    return null;
                }
              },
            );

        expect(
          () => service.startDeviceLock(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('System overlay permission is required'),
            ),
          ),
        );
      });

      testWidgets('throws exception when platform call fails', (tester) async {
        // Mock platform exception on startDeviceLock
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                switch (methodCall.method) {
                  case 'hasDeviceAdminPermission':
                    return true;
                  case 'hasOverlayPermission':
                    return true;
                  case 'startDeviceLock':
                    throw PlatformException(
                      code: 'ERROR',
                      message: 'Lock failed',
                    );
                  default:
                    return null;
                }
              },
            );

        if (Platform.isAndroid) {
          expect(
            () => service.startDeviceLock(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Failed to start device lock: Lock failed'),
              ),
            ),
          );
        } else {
          expect(
            () => service.startDeviceLock(),
            throwsA(isA<UnsupportedError>()),
          );
        }
      });
    });

    group('endDeviceLock', () {
      testWidgets('ends device lock successfully', (tester) async {
        // Skip on non-Android platforms
        try {
          // First start the lock
          await service.startDeviceLock();
          expect(service.isLocked, isTrue);

          // Clear previous method calls
          methodCalls.clear();

          // End the lock
          await service.endDeviceLock();

          expect(methodCalls.length, equals(1));
          expect(methodCalls.first.method, equals('endDeviceLock'));
          expect(service.isLocked, isFalse);
        } on UnsupportedError {
          // Expected on non-Android platforms
          expect(service.isLocked, isFalse);
        }
      });

      testWidgets('resets lock state even when platform call fails', (
        tester,
      ) async {
        // Skip on non-Android platforms
        try {
          // First start the lock
          await service.startDeviceLock();
          expect(service.isLocked, isTrue);

          // Mock platform exception on endDeviceLock
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('com.focuslock/device_admin'),
                (MethodCall methodCall) async {
                  if (methodCall.method == 'endDeviceLock') {
                    throw PlatformException(
                      code: 'ERROR',
                      message: 'Unlock failed',
                    );
                  }
                  return null;
                },
              );

          await service.endDeviceLock();

          expect(service.isLocked, isFalse); // Should reset state even on error
        } on UnsupportedError {
          // Expected on non-Android platforms
          expect(service.isLocked, isFalse);
        }
      });
    });

    group('requestDeviceAdminPermission', () {
      testWidgets('returns true when permission is granted', (tester) async {
        final result = await service.requestDeviceAdminPermission();

        if (Platform.isAndroid) {
          expect(result, isTrue);
          expect(methodCalls.length, equals(1));
          expect(
            methodCalls.first.method,
            equals('requestDeviceAdminPermission'),
          );
        } else {
          // On non-Android platforms, should return false
          expect(result, isFalse);
        }
      });

      testWidgets('returns false when platform exception occurs', (
        tester,
      ) async {
        // Mock platform exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Request failed',
                );
              },
            );

        final result = await service.requestDeviceAdminPermission();

        expect(result, isFalse);
      });
    });

    group('requestOverlayPermission', () {
      testWidgets('returns true when permission is granted', (tester) async {
        final result = await service.requestOverlayPermission();

        if (Platform.isAndroid) {
          expect(result, isTrue);
          expect(methodCalls.length, equals(1));
          expect(methodCalls.first.method, equals('requestOverlayPermission'));
        } else {
          // On non-Android platforms, should return false
          expect(result, isFalse);
        }
      });

      testWidgets('returns false when platform exception occurs', (
        tester,
      ) async {
        // Mock platform exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.focuslock/device_admin'),
              (MethodCall methodCall) async {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Request failed',
                );
              },
            );

        final result = await service.requestOverlayPermission();

        expect(result, isFalse);
      });
    });

    group('isLocked getter', () {
      testWidgets('returns false initially', (tester) async {
        expect(service.isLocked, isFalse);
      });

      testWidgets('returns true after starting device lock', (tester) async {
        // Skip on non-Android platforms
        try {
          await service.startDeviceLock();
          expect(service.isLocked, isTrue);
        } on UnsupportedError {
          // Expected on non-Android platforms
          expect(service.isLocked, isFalse);
        }
      });

      testWidgets('returns false after ending device lock', (tester) async {
        // Skip on non-Android platforms
        try {
          await service.startDeviceLock();
          await service.endDeviceLock();
          expect(service.isLocked, isFalse);
        } on UnsupportedError {
          // Expected on non-Android platforms
          expect(service.isLocked, isFalse);
        }
      });
    });
  });
}
