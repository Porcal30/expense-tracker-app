import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/services/secure_storage_service.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/budget_remote_datasource.dart';
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/expense_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/security_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final secureStorageService = SecureStorageService();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => secureStorageService),
        Provider(create: (_) => ExpenseRemoteDataSource()),
        Provider(create: (_) => CategoryRemoteDataSource()),
        Provider(create: (_) => BudgetRemoteDataSource()),
        ProxyProvider<CategoryRemoteDataSource, AuthRemoteDataSource>(
          update: (_, categoryDs, p) => AuthRemoteDataSource(categoryDataSource: categoryDs),
        ),
        ProxyProvider<AuthRemoteDataSource, AuthRepository>(
          update: (_, ds, p) => AuthRepository(ds),
        ),
        ProxyProvider<ExpenseRemoteDataSource, ExpenseRepository>(
          update: (_, ds, p) => ExpenseRepository(ds),
        ),
        ProxyProvider<CategoryRemoteDataSource, CategoryRepository>(
          update: (_, ds, p) => CategoryRepository(ds),
        ),
        ProxyProvider<BudgetRemoteDataSource, BudgetRepository>(
          update: (_, ds, p) => BudgetRepository(ds),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (_) => AuthProvider(null),
          update: (_, repo, previous) => previous!..attachRepository(repo),
        ),
        ChangeNotifierProxyProvider<ExpenseRepository, ExpenseProvider>(
          create: (_) => ExpenseProvider(null),
          update: (_, repo, previous) => previous!..attachRepository(repo),
        ),
        ChangeNotifierProxyProvider<CategoryRepository, CategoryProvider>(
          create: (_) => CategoryProvider(null),
          update: (_, repo, previous) => previous!..attachRepository(repo),
        ),
        ChangeNotifierProxyProvider2<BudgetRepository, ExpenseProvider, BudgetProvider>(
          create: (_) => BudgetProvider(null, null),
          update: (_, budgetRepo, expenseProvider, previous) =>
              previous!..attachRepositories(budgetRepo, expenseProvider),
        ),
        ChangeNotifierProxyProvider<SecureStorageService, SecurityProvider>(
          create: (_) => SecurityProvider(null),
          update: (_, storage, previous) =>
              previous!..attachServices(storage),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}