import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_remote_datasource.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoryRemoteDataSource? _categoryDataSource;

  AuthRemoteDataSource({CategoryRemoteDataSource? categoryDataSource})
      : _categoryDataSource = categoryDataSource;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Create user document
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'pinEnabled': false,
    });

    // Seed default categories for new user
    if (_categoryDataSource != null) {
      try {
        await _categoryDataSource.seedDefaultCategories(uid);
      } catch (e) {
        // Silently fail if seeding doesn't complete
        // User can add categories manually if needed
      }
    }

    return credential;
  }

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();
}