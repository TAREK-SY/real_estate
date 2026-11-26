import 'package:shared_preferences/shared_preferences.dart';

/// Whether someone has entered the app. There is no account system: entering
/// from the sign-in screen starts a guest session that survives restarts.
class SessionStore {
  SessionStore(this._prefs);

  static const String signedInKey = 'session.signedIn';

  final SharedPreferences _prefs;

  bool get isSignedIn => _prefs.getBool(signedInKey) ?? false;

  Future<void> signInAsGuest() => _prefs.setBool(signedInKey, true);

  Future<void> signOut() => _prefs.remove(signedInKey);
}
