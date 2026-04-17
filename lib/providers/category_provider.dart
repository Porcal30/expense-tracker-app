import 'dart:async';
import 'package:flutter/material.dart';

import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryRepository? _repository;
  StreamSubscription<List<Category>>? _subscription;

  CategoryProvider(this._repository);

  List<Category> _categories = [];

  List<Category> get categories => _categories;

  void attachRepository(CategoryRepository repo) {
    _repository = repo;
  }

  void bindCategories(String uid) {
    _subscription?.cancel();
    _subscription = _repository!.watchCategories(uid).listen((data) {
      _categories = data;
      notifyListeners();
    });
  }

  Future<void> addCategory(Category category) async {
    await _repository!.addCategory(category);
  }

  Future<void> deleteCategory(String uid, String categoryId) async {
    await _repository!.deleteCategory(uid, categoryId);
  }

  Category? getById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _subscription?.cancel();
    _categories = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}