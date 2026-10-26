import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  /// Firebase only deletes an account that signed in recently, so the
  /// password is asked for again. Throws on a wrong password.
  Future<void> confirmPassword(String password) {
    final user = _auth.currentUser!;
    return user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password));
  }

  /// Signs out as a side effect. Call [confirmPassword] first.
  Future<void> deleteAccount() => _auth.currentUser!.delete();
}
