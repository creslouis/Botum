import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';

class AccountCollisionException implements Exception {
  final String email;
  final List<String> existingProviders;
  final AuthCredential pendingCredential;

  AccountCollisionException({
    required this.email,
    required this.existingProviders,
    required this.pendingCredential,
  });

  @override
  String toString() {
    return 'Account collision: $email already uses $existingProviders';
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (_auth.currentUser?.isAnonymous == true) {
      return await _linkAnonymousWithEmail(
        email: email.trim(),
        password: password,
      );
    }

    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> _linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle() async {
    await GoogleSignIn.instance.signOut();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email ?? googleUser.email;
        final pendingCredential = credential;
        throw AccountCollisionException(
          email: email,
          existingProviders: ['password'],
          pendingCredential: pendingCredential,
        );
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Facebook sign in was cancelled.',
      );
    }

    if (result.status == LoginStatus.failed) {
      throw FirebaseAuthException(
        code: 'facebook-sign-in-failed',
        message: result.message ?? 'Facebook sign in failed.',
      );
    }

    final OAuthCredential credential =
        FacebookAuthProvider.credential(result.accessToken!.tokenString);

    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email ?? '';
        final pendingCredential = credential;
        throw AccountCollisionException(
          email: email,
          existingProviders: ['password'],
          pendingCredential: pendingCredential,
        );
      }
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    await _auth.currentUser?.reload();
  }

  Future<void> updatePhotoURL(String photoUrl) async {
    await _auth.currentUser?.updatePhotoURL(photoUrl);
    await _auth.currentUser?.reload();
  }

  Future<UserCredential> reAuthAndLink({
    required String provider,
    required AuthCredential pendingCredential,
  }) async {
    if (provider == 'google.com') {
      final googleCred = await _getGoogleCredential();
      await _auth.currentUser!
          .linkWithCredential(googleCred);
    } else if (provider == 'facebook.com') {
      final fbCred = await _getFacebookCredential();
      await _auth.currentUser!
          .linkWithCredential(fbCred);
    }

    return await _auth.currentUser!
        .linkWithCredential(pendingCredential);
  }

  Future<AuthCredential> _getGoogleCredential() async {
    await GoogleSignIn.instance.signOut();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    return GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
  }

  Future<AuthCredential> _getFacebookCredential() async {
    final result = await FacebookAuth.instance.login();
    return FacebookAuthProvider.credential(result.accessToken!.tokenString);
  }

  UserModel mapFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      role: 'user',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      providers: user.providerData.map((p) => p.providerId).toList(),
    );
  }
}
