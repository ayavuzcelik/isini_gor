import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Oturum yönetimi.
///
/// Şimdilik Google girişini taklit ediyor. Firebase bağlanınca sadece
/// [signInWithGoogle] ve [signOut] gövdeleri `google_sign_in` +
/// `FirebaseAuth` çağrılarıyla değişecek; ekranlar aynı kalacak.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  AppUser? _user;
  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  bool _busy = false;
  bool get busy => _busy;

  Future<AppUser> signInWithGoogle() async {
    _busy = true;
    notifyListeners();

    // TODO(firebase): GoogleSignIn().signIn() -> FirebaseAuth.signInWithCredential
    await Future<void>.delayed(const Duration(milliseconds: 900));

    _user = const AppUser(
      id: 'demo-user-1',
      name: 'Adem Çelik',
      email: 'ademclk97@gmail.com',
      phone: '0555 000 00 00',
    );

    _busy = false;
    notifyListeners();
    return _user!;
  }

  Future<void> signOut() async {
    // TODO(firebase): FirebaseAuth.instance.signOut()
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _user = null;
    notifyListeners();
  }

  void updatePhone(String phone) {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(phone: phone);
    notifyListeners();
  }
}
