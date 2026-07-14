import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProviderConnection {
  final String providerId;
  final String label;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isConnected;
  final bool isAvailable;

  const AuthProviderConnection({
    required this.providerId,
    required this.label,
    required this.isConnected,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAvailable = true,
  });
}

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

  AuthState get state => _state;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  String? get errorMessage => _errorMessage;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get hasPasswordProvider => _authService.hasProvider('password');

  List<AuthProviderConnection> get socialConnections {
    final current = _firebaseUser;
    final providers = current?.providerData ?? <UserInfo>[];

    AuthProviderConnection build(String providerId, String label) {
      final match = providers.cast<UserInfo?>().firstWhere(
        (provider) => provider?.providerId == providerId,
        orElse: () => null,
      );

      return AuthProviderConnection(
        providerId: providerId,
        label: label,
        isConnected: match != null,
        email: match?.email,
        displayName: match?.displayName,
        photoUrl: match?.photoURL ?? _userModel?.socialPhotoUrls[providerId],
        isAvailable: providerId != 'telegram',
      );
    }

    return [
      build('google.com', 'Google'),
      build('facebook.com', 'Facebook'),
      const AuthProviderConnection(
        providerId: 'telegram',
        label: 'Telegram',
        isConnected: false,
        isAvailable: false,
      ),
    ];
  }

  List<AuthProviderConnection> get photoSources {
    return socialConnections
        .where(
          (connection) =>
              connection.isConnected &&
              (connection.photoUrl?.isNotEmpty ?? false),
        )
        .toList();
  }

  Future<void> _onAuthStateChanged(User? user) async {
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

    final currentUserModel = _authService.mapFirebaseUser(user);
    final socialPhotoUrls = <String, String>{
      ...?_userModel?.socialPhotoUrls,
      ...?userDocSocialPhotos(),
    };
    for (final provider in user.providerData) {
      if (provider.photoURL != null && provider.photoURL!.isNotEmpty) {
        socialPhotoUrls[provider.providerId] = provider.photoURL!;
      }
    }
    if (currentUserModel.providers.contains('facebook.com')) {
      final facebookPhotoUrl = await _authService.getFacebookProfilePhotoUrl();
      if (facebookPhotoUrl != null && facebookPhotoUrl.isNotEmpty) {
        socialPhotoUrls['facebook.com'] = facebookPhotoUrl;
      }
    }

    final userDoc = await _firestoreService.getUser(user.uid);
    final isAutoAdmin = AppConstants.adminEmails.contains(
      currentUserModel.email.toLowerCase().trim(),
    );

    if (userDoc != null) {
      _userModel = userDoc.copyWith(
        email: currentUserModel.email,
        displayName: currentUserModel.displayName.isNotEmpty
            ? currentUserModel.displayName
            : userDoc.displayName,
        photoUrl: currentUserModel.photoUrl ?? userDoc.photoUrl,
        phoneNumber: currentUserModel.phoneNumber ?? userDoc.phoneNumber,
        providers: currentUserModel.providers,
        role: (isAutoAdmin && userDoc.role != AppConstants.userRoleAdmin)
            ? AppConstants.userRoleAdmin
            : userDoc.role,
        socialPhotoUrls: {...userDoc.socialPhotoUrls, ...socialPhotoUrls},
      );
      await _firestoreService.updateUser(user.uid, {
        'email': _userModel!.email,
        'displayName': _userModel!.displayName,
        'photoUrl': _userModel!.photoUrl,
        'phoneNumber': _userModel!.phoneNumber,
        'providers': _userModel!.providers,
        'role': _userModel!.role,
        'socialPhotoUrls': _userModel!.socialPhotoUrls,
      });
    } else {
      _userModel = currentUserModel.copyWith(
        socialPhotoUrls: socialPhotoUrls,
        role: isAutoAdmin
            ? AppConstants.userRoleAdmin
            : AppConstants.userRoleUser,
      );
      await _firestoreService.createUser(_userModel!);
    }

    _state = AuthState.authenticated;
    notifyListeners();
  }

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
      final isAutoAdmin = AppConstants.adminEmails.contains(
        email.toLowerCase().trim(),
      );
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName ?? user.displayName ?? '',
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
        role: isAutoAdmin
            ? AppConstants.userRoleAdmin
            : AppConstants.userRoleUser,
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

  Future<void> resolveCollisionWithEmail({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    await _run(
      () => _authService.resolveCollisionWithEmail(
        email: email,
        password: password,
        pendingCredential: pendingCredential,
      ),
    );
  }

  Future<void> resolveCollisionWithProvider({
    required String providerId,
    required AuthCredential pendingCredential,
  }) async {
    await _run(
      () => _authService.resolveCollisionWithProvider(
        providerId: providerId,
        pendingCredential: pendingCredential,
      ),
    );
  }

  Future<void> linkProvider(String providerId) async {
    await _run(() async {
      if (providerId == 'google.com') {
        await _authService.linkGoogle();
      } else if (providerId == 'facebook.com') {
        await _authService.linkFacebook();
      } else {
        throw FirebaseAuthException(
          code: 'unsupported-provider',
          message: 'This social provider is not supported yet.',
        );
      }
    });
  }

  Future<void> unlinkProvider(String providerId) async {
    if ((_firebaseUser?.providerData.length ?? 0) <= 1 &&
        !hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'requires-additional-sign-in-method',
        message:
            'Add another sign-in method or set a password before disconnecting this account.',
      );
    }

    await _run(() => _authService.unlinkProvider(providerId));
  }

  Future<void> setPassword(String password) async {
    await _run(() => _authService.setPassword(password: password));
  }

  Future<void> sendPasswordSetupEmail() async {
    final email = _firebaseUser?.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'No email address is available for this account.',
      );
    }
    await _run(() => _authService.sendPasswordResetEmail(email));
  }

  Future<void> chooseProfilePhoto(String photoUrl) async {
    await updateProfile(photoUrl: photoUrl);
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

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
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
          'displayName': displayName ?? _userModel!.displayName,
          'photoUrl': photoUrl ?? _userModel!.photoUrl,
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

  Future<void> _run(Future<dynamic> Function() action) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await _refreshCurrentUser();
    } on AccountCollisionException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        await _refreshCurrentUser();
      }
      _errorMessage = _getErrorMessage(e);
      _state = _firebaseUser == null
          ? AuthState.unauthenticated
          : AuthState.authenticated;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _state = _firebaseUser == null
          ? AuthState.unauthenticated
          : AuthState.authenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _refreshCurrentUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    await currentUser.reload();
    final refreshed = _authService.currentUser;
    if (refreshed != null) {
      await _onAuthStateChanged(refreshed);
    }
  }

  Map<String, String>? userDocSocialPhotos() {
    return _userModel?.socialPhotoUrls;
  }

  String providerLabel(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Facebook';
      case 'password':
        return 'Email and Password';
      case 'telegram':
        return 'Telegram';
      default:
        return providerId;
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
          return error.message ?? 'An account already exists with this email.';
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
        case 'sign-in-timeout':
          return error.message ?? 'Google sign in timed out. Please try again.';
        case 'provider-already-linked':
          return 'This provider is already connected to your account.';
        case 'credential-already-in-use':
          return 'This social account is already linked to another Botum account.';
        case 'requires-recent-login':
          return 'Please sign in again before changing this security setting.';
        case 'requires-additional-sign-in-method':
        case 'missing-email':
        case 'unsupported-provider':
          return error.message ??
              'Please review the account setup and try again.';
        default:
          return error.message ?? 'An unexpected error occurred.';
      }
    }
    return error.toString();
  }
}
