import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';

class CategoryRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('categories');
  }

  Stream<List<Category>> watchCategories(String uid) {
    return _collection(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addCategory(Category category) async {
    await _collection(category.userId).doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    await _collection(uid).doc(categoryId).delete();
  }

  Future<void> seedDefaultCategories(String uid) async {
    // Check if user already has categories to avoid duplicates
    final existingCategories = await _collection(uid).limit(1).get();
    if (existingCategories.docs.isNotEmpty) {
      return; // Categories already exist, don't seed
    }

    // Define default categories with distinct colors
    final defaultCategories = [
      Category(
        id: 'food',
        userId: uid,
        name: 'Food',
        colorValue: Colors.orange.toARGB32(),
      ),
      Category(
        id: 'transport',
        userId: uid,
        name: 'Transport',
        colorValue: Colors.blue.toARGB32(),
      ),
      Category(
        id: 'bills',
        userId: uid,
        name: 'Bills',
        colorValue: Colors.red.toARGB32(),
      ),
      Category(
        id: 'shopping',
        userId: uid,
        name: 'Shopping',
        colorValue: Colors.purple.toARGB32(),
      ),
    ];

    // Seed all default categories in a batch
    final batch = _firestore.batch();
    for (final category in defaultCategories) {
      final docRef = _collection(uid).doc(category.id);
      batch.set(docRef, category.toMap());
    }
    await batch.commit();
  }
}