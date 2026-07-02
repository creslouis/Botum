import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthState _state = AuthState.initial;
  UserModel? _userModel;
  User? _firebaseUser;
  String? _errorMessage;
  bool _isGuest = false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ─── Getters ─────────────────────────────────────────────

  AuthState get state => _state;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  String? get errorMessage => _errorMessage;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isAdmin => _userModel?.isAdmin ?? false;

  // ─── Auth State Listener ─────────────────────────────────

  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _firebaseUser = null;
      _userModel = null;
      _isGuest = false;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }

    _firebaseUser = user;
    _isGuest = user.isAnonymous;

    if (user.isAnonymous) {
      _userModel = _authService.mapFirebaseUser(user);
      _state = AuthState.authenticated;
      notifyListeners();
      return;
    }

    // Fetch user from Firestore
    final userDoc = await _firestoreService.getUser(user.uid);
    if (userDoc != null) {
      _userModel = userDoc;
    } else {
      _userModel = _authService.mapFirebaseUser(user);
      await _firestoreService.createUser(_userModel!);
    }

    _state = AuthState.authenticated;
    notifyListeners();
  }

  // ─── Auth Methods ────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    await _run(() => _authService.signInWithEmail(email, password));
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _run(() async {
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await _authService.updateDisplayName(displayName);
      }
      final user = credential.user!;
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName ?? user.displayName ?? '',
        photoUrl: user.photoURL,
        role: 'user',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        providers: user.providerData.map((p) => p.providerId).toList(),
      );
      await _firestoreService.createUser(userModel);
      return credential;
    });
  }

  Future<void> signInWithGoogle() async {
    await _run(() => _authService.signInWithGoogle());
  }

  Future<void> signInWithFacebook() async {
    await _run(() => _authService.signInWithFacebook());
  }

  Future<void> signInAsGuest() async {
    await _run(() => _authService.signInAnonymously());
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _firebaseUser = null;
    _isGuest = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _run(() => _authService.sendPasswordResetEmail(email));
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (displayName != null) {
        await _authService.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _authService.updatePhotoURL(photoUrl);
      }

      if (_userModel != null) {
        _userModel = _userModel!.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
        );
        await _firestoreService.updateUser(_userModel!.uid, {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
        });
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Helper ──────────────────────────────────────────────

  Future<void> _run(Future<dynamic> Function() action) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on AccountCollisionException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      _state = AuthState.error;
      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _state = AuthState.error;
      notifyListeners();
    }
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'sign-in-cancelled':
          return 'Sign in was cancelled.';
        default:
          return error.message ?? 'An unexpected error occurred.';
      }
    }
    return error.toString();
  }
}
