import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Google + Firebase Auth ile oturum yönetimi.
///
/// [FirebaseAuth.authStateChanges] dinlenir; oturum açılıp kapandıkça
/// dinleyiciler bilgilendirilir ve `_AuthGate` ekranı değiştirir.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  bool _busy = false;
  bool get busy => _busy;

  bool _initialized = false;

  /// `main()` içinde Firebase hazır olduktan sonra bir kez çağrılır.
  Future<void> init({String? serverClientId}) async {
    if (_initialized) return;
    _initialized = true;

    // google_sign_in 7.x: kullanmadan önce initialize edilmeli.
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);

    _user = _toAppUser(_auth.currentUser);
    _auth.authStateChanges().listen((firebaseUser) {
      _user = _toAppUser(firebaseUser);
      notifyListeners();
    });
  }

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'İsimsiz kullanıcı',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      phone: user.phoneNumber,
    );
  }

  Future<void> signInWithGoogle() async {
    _busy = true;
    notifyListeners();

    try {
      // Hesap seçiciyi açar. Kullanıcı vazgeçerse GoogleSignInException atar.
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google kimlik doğrulaması eksik döndü.',
        );
      }

      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      // _user, authStateChanges dinleyicisinden gelir.
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
