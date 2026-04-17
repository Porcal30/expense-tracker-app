import '../datasources/category_remote_datasource.dart';
import '../models/category.dart';

class CategoryRepository {
  final CategoryRemoteDataSource _remote;

  CategoryRepository(this._remote);

  Stream<List<Category>> watchCategories(String uid) => _remote.watchCategories(uid);
  Future<void> addCategory(Category category) => _remote.addCategory(category);
  Future<void> deleteCategory(String uid, String categoryId) =>
      _remote.deleteCategory(uid, categoryId);
}