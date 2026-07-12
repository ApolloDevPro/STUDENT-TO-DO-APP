import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // OAuth web client ID required for Google Sign-In on Android (Google Sign-In
  // v7 uses the Credential Manager flow). Get it from the Firebase console:
  //   Authentication -> Sign-in method -> Google -> Web SDK configuration
  // (it's the "client_id" of the web client, also found as client_type 3 in
  // google-services.json). Replace the placeholder below.
  static const String _googleWebClientId = 'REPLACE_WITH_WEB_CLIENT_ID';

  AuthProvider() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }
  
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? _successMessage;
  String? get successMessage => _successMessage;

  void setSuccessMessage(String message) => _successMessage = message;
  void clearSuccessMessage() => _successMessage = null;

  // Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  // Sign In
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password.';
      }
      return e.message;
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  // Sign In with Google
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  Future<String?> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await _googleSignIn.initialize(serverClientId: _googleWebClientId);
        _googleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await _auth.signInWithCredential(credential);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null; // User cancelled
      }
      return e.description ?? 'Google sign-in failed.';
    } catch (e) {
      return 'An error occurred during Google sign-in.';
    }
  }

  // Update display name
  Future<String?> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _auth.currentUser?.reload();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to update display name.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
}