import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:focuslock/features/auth/domain/entities/user.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:focuslock/features/auth/presentation/pages/login_screen.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_bloc.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_state.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_event.dart';
import 'package:focuslock/features/permissions/presentation/screen/permissions_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockPermissionBloc extends MockBloc<PermissionEvent, PermissionState>
    implements PermissionBloc {}

void main() {
  group('Authentication and Permissions Flow Integration Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockPermissionBloc mockPermissionBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockPermissionBloc = MockPermissionBloc();
    });

    Widget createTestApp(Widget child) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<PermissionBloc>.value(value: mockPermissionBloc),
        ],
        child: MaterialApp(
          home: child,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/permissions': (context) => const PermissionsScreen(),
            '/home': (context) =>
                const Scaffold(body: Center(child: Text('Home Screen'))),
          },
        ),
      );
    }

    testWidgets(
      'should navigate from login to permissions after successful authentication',
      (tester) async {
        // Arrange
        const user = User(
          id: '123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          isAuthenticated: true,
        );

        whenListen(
          mockAuthBloc,
          Stream.fromIterable([
            const AuthInitial(),
            const AuthLoading(),
            const AuthAuthenticated(user),
          ]),
          initialState: const AuthInitial(),
        );

        whenListen(
          mockPermissionBloc,
          Stream.fromIterable([const PermissionLoading()]),
          initialState: const PermissionLoading(),
        );

        // Act
        await tester.pumpWidget(createTestApp(const LoginScreen()));
        await tester.pump();

        // Find and tap Google Sign-In button
        final googleSignInButton = find.text('Continue with Google');
        expect(googleSignInButton, findsOneWidget);
        await tester.tap(googleSignInButton);

        await tester.pump(); // Trigger state change
        await tester.pump(
          const Duration(milliseconds: 400),
        ); // Wait for navigation

        // Assert
        expect(find.byType(PermissionsScreen), findsOneWidget);
      },
    );

    testWidgets('should show error message when authentication fails', (
      tester,
    ) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          const AuthInitial(),
          const AuthLoading(),
          const AuthError('Authentication failed'),
        ]),
        initialState: const AuthInitial(),
      );

      // Act
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pump();

      // Trigger authentication
      final googleSignInButton = find.text('Continue with Google');
      await tester.tap(googleSignInButton);
      await tester.pump();

      // Assert
      expect(find.text('Authentication failed'), findsOneWidget);
    });

    testWidgets('should show permissions screen with proper state management', (
      tester,
    ) async {
      // Arrange
      final permissions = [
        const Permission(
          type: PermissionType.notification,
          status: PermissionStatus.granted,
          title: 'Notifications',
          description: 'Allow notifications',
          icon: Icons.notifications,
        ),
        const Permission(
          type: PermissionType.admin,
          status: PermissionStatus.pending,
          title: 'Device Admin',
          description: 'Allow device admin',
          icon: Icons.admin_panel_settings,
        ),
      ];

      const progress = PermissionProgress(
        totalPermissions: 2,
        grantedPermissions: 1,
        progressPercentage: 0.5,
        isComplete: false,
      );

      whenListen(
        mockPermissionBloc,
        Stream.fromIterable([
          const PermissionLoading(),
          PermissionLoaded(permissions: permissions, progress: progress),
        ]),
        initialState: const PermissionLoading(),
      );

      // Act
      await tester.pumpWidget(createTestApp(const PermissionsScreen()));
      await tester.pump();
      await tester.pump(); // Allow state to update

      // Assert
      expect(find.text('App Permissions'), findsOneWidget);
      expect(find.text('Continue Anyway'), findsOneWidget);
    });
  });
}
