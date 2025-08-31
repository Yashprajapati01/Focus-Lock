import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:focuslock/features/auth/presentation/pages/login_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthBloc])
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('should display welcome message and buttons', (tester) async {
      // arrange
      when(mockAuthBloc.state).thenReturn(const AuthInitial());
      when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.text('Welcome to FocusLock'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('should show loading overlay when AuthLoading', (tester) async {
      // arrange
      when(mockAuthBloc.state).thenReturn(const AuthLoading());
      when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when AuthError', (tester) async {
      // arrange
      const errorMessage = 'Sign in failed';
      when(mockAuthBloc.state).thenReturn(const AuthError(errorMessage));
      when(mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
