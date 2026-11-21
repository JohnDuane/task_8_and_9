
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void>? _googleSignInInit;

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    try {
      // WEB
      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();

        final UserCredential result =
            await _auth.signInWithPopup(provider);

        return result.user;
      }

      // ANDROID
      _googleSignInInit ??=
          GoogleSignIn.instance.initialize();

      await _googleSignInInit;

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google ID token is missing.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

      return result.user;

    } on FirebaseAuthException {
      rethrow;
    }
  }

  // GET CURRENT USER
  User? get currentUser => _auth.currentUser;

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();

    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
