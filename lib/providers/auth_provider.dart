import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthRepository? _repository;
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._repository);

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;

  void attachRepository(AuthRepository repo) {
    if (_repository == repo) return;
    _repository = repo;
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    if (_repository == null) return;
    _user = _repository!.currentUser;
    _subscription = _repository!.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _repository!.login(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _repository!.register(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository?.logout();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}