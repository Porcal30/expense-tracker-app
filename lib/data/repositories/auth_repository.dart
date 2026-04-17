import 'package:firebase_auth/firebase_auth.dart';

import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepository(this._remote);

  User? get currentUser => _remote.currentUser;
  Stream<User?> authStateChanges() => _remote.authStateChanges();

  Future<UserCredential> register(String email, String password) {
    return _remote.register(email, password);
  }

  Future<UserCredential> login(String email, String password) {
    return _remote.login(email, password);
  }

  Future<void> logout() => _remote.logout();
}