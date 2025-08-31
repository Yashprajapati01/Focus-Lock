import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class GoogleSignInService {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

@LazySingleton(as: GoogleSignInService)
class GoogleSignInServiceImpl implements GoogleSignInService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  GoogleSignInServiceImpl()
    : _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // This helps resolve the PigeonUserDetails casting issue
        signInOption: SignInOption.standard,
      ),
      _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Clear any existing sign-in state to prevent conflicts
      await _googleSignIn.signOut();

      // Attempt to sign in with Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        throw const GoogleSignInFailure('Sign in was cancelled by user');
      }

      // Get authentication details from the request
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      // Validate that we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw const GoogleSignInFailure(
          'Failed to get authentication tokens from Google',
        );
      }

      // Create a new credential for Firebase Auth
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw const GoogleSignInFailure(
          'Failed to get user information from Firebase',
        );
      }

      // Return the user model
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAuthenticated: true,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with a different sign-in method';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid or has expired';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled for this project';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this credential';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Invalid verification code';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID';
          break;
        default:
          errorMessage = e.message ?? 'An unknown Firebase Auth error occurred';
      }
      throw GoogleSignInFailure('Firebase Auth Error: $errorMessage');
    } catch (e) {
      if (e is GoogleSignInFailure) rethrow;

      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        throw const GoogleSignInFailure(
          'Google Sign-In configuration error. Please check your Firebase project setup and SHA-1 fingerprints.',
        );
      }

      throw GoogleSignInFailure(
        'Failed to sign in with Google: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from both Google and Firebase
      await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);
    } catch (e) {
      throw GoogleSignInFailure('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) return null;

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAuthenticated: true,
      );
    } catch (e) {
      throw GoogleSignInFailure('Failed to get current user: ${e.toString()}');
    }
  }
}
