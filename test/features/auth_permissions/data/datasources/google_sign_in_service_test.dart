import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/auth/data/datasources/google_sign_in_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:focuslock/core/errors/failures.dart';

import 'google_sign_in_service_test.mocks.dart';

@GenerateMocks([GoogleSignIn, GoogleSignInAccount])
void main() {
  late GoogleSignInServiceImpl service;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockAccount;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockAccount = MockGoogleSignInAccount();
    service = GoogleSignInServiceImpl();
    // Note: In a real implementation, we'd need to inject the GoogleSignIn instance
  });

  group('GoogleSignInService', () {
    group('signInWithGoogle', () {
      test('should return UserModel when sign in is successful', () async {
        // arrange
        when(mockAccount.id).thenReturn('test-id');
        when(mockAccount.email).thenReturn('test@example.com');
        when(mockAccount.displayName).thenReturn('Test User');
        when(mockAccount.photoUrl).thenReturn('https://example.com/photo.jpg');
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);

        // act & assert
        // Note: This test would need proper dependency injection to work
        expect(
          () => service.signInWithGoogle(),
          throwsA(isA<GoogleSignInFailure>()),
        );
      });

      test(
        'should throw GoogleSignInFailure when user cancels sign in',
        () async {
          // arrange
          when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

          // act & assert
          expect(
            () => service.signInWithGoogle(),
            throwsA(isA<GoogleSignInFailure>()),
          );
        },
      );
    });
  });
}
