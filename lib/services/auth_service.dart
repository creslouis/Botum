import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

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
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get userChanges => _auth.userChanges();
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final existingUser = await _firestoreService.getUserByEmail(trimmedEmail);

    if (existingUser != null && _auth.currentUser?.isAnonymous != true) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: _formatExistingProvidersMessage(existingUser.providers),
      );
    }

    if (_auth.currentUser?.isAnonymous == true) {
      return _linkAnonymousWithEmail(email: trimmedEmail, password: password);
    }

    return _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
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
    return _auth.currentUser!.linkWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      try {
        return await _auth
            .signInWithPopup(provider)
            .timeout(const Duration(seconds: 45));
      } on TimeoutException {
        throw FirebaseAuthException(
          code: 'sign-in-timeout',
          message:
              'Google sign in timed out. Please allow pop-ups and try again.',
        );
      }
    }

    await GoogleSignIn.instance.signOut();
    final googleUser = await GoogleSignIn.instance.authenticate().timeout(
      const Duration(seconds: 45),
    );
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _signInWithCredential(
      credential,
      fallbackEmailProvider: googleUser.email,
    );
  }

  Future<UserCredential> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
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

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );
    final userData = await FacebookAuth.instance.getUserData();

    return _signInWithCredential(
      credential,
      fallbackEmailProvider: userData['email'] as String?,
    );
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

  Future<String?> getFacebookProfilePhotoUrl() async {
    try {
      final userData = await FacebookAuth.instance.getUserData(
        fields: 'picture.width(200),email,name',
      );
      final picture = userData['picture'] as Map<String, dynamic>?;
      final data = picture?['data'] as Map<String, dynamic>?;
      return data?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential> resolveCollisionWithEmail({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    final current = _auth.currentUser;
    if (current != null && current.email == email) {
      await current.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email.trim(), password: password),
      );
      return current.linkWithCredential(pendingCredential);
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!.linkWithCredential(pendingCredential);
  }

  Future<UserCredential> resolveCollisionWithProvider({
    required String providerId,
    required AuthCredential pendingCredential,
  }) async {
    UserCredential credential;
    if (providerId == 'google.com') {
      credential = await _auth.signInWithCredential(
        await _getGoogleCredential(),
      );
    } else if (providerId == 'facebook.com') {
      credential = await _auth.signInWithCredential(
        await _getFacebookCredential(),
      );
    } else {
      throw FirebaseAuthException(
        code: 'unsupported-provider',
        message: 'This provider is not supported for automatic linking yet.',
      );
    }

    return credential.user!.linkWithCredential(pendingCredential);
  }

  Future<void> linkGoogle() async {
    await _auth.currentUser!.linkWithCredential(await _getGoogleCredential());
    await _auth.currentUser!.reload();
  }

  Future<void> linkFacebook() async {
    await _auth.currentUser!.linkWithCredential(await _getFacebookCredential());
    await _auth.currentUser!.reload();
  }

  Future<void> unlinkProvider(String providerId) async {
    await _auth.currentUser!.unlink(providerId);
    await _auth.currentUser!.reload();
  }

  Future<void> setPassword({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Add an email address before setting a password.',
      );
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (hasPasswordProvider) {
      await user.updatePassword(password);
    } else {
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    }

    await user.reload();
  }

  bool hasProvider(String providerId) {
    return _auth.currentUser?.providerData.any(
          (provider) => provider.providerId == providerId,
        ) ??
        false;
  }

  UserModel mapFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      role: 'user',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      providers: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  Future<UserCredential> _signInWithCredential(
    AuthCredential credential, {
    String? fallbackEmailProvider,
  }) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = (e.email ?? fallbackEmailProvider ?? '').trim();
        final existingUser = email.isEmpty
            ? null
            : await _firestoreService.getUserByEmail(email);
        final existingProviders = existingUser?.providers ?? <String>[];
        throw AccountCollisionException(
          email: email,
          existingProviders: existingProviders.isEmpty
              ? <String>['password']
              : existingProviders,
          pendingCredential: credential,
        );
      }
      rethrow;
    }
  }

  Future<AuthCredential> _getGoogleCredential() async {
    await GoogleSignIn.instance.signOut();
    final googleUser = await GoogleSignIn.instance.authenticate().timeout(
      const Duration(seconds: 45),
    );
    final googleAuth = googleUser.authentication;
    return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
  }

  Future<AuthCredential> _getFacebookCredential() async {
    final result = await FacebookAuth.instance.login(
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

    return FacebookAuthProvider.credential(result.accessToken!.tokenString);
  }

  String _formatExistingProvidersMessage(List<String> methods) {
    final labels = methods.map(_providerLabel).toList();
    return 'An account already exists with this email. Sign in with ${labels.join(' or ')} and link this method from Profile.';
  }

  String _providerLabel(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Facebook';
      case 'password':
        return 'email and password';
      default:
        return providerId;
    }
  }
}
