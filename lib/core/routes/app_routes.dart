import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/budget/set_budget_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/expenses/add_edit_expense_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/pin/pin_setup_screen.dart';
import '../../screens/pin/pin_unlock_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const pinSetup = '/pin-setup';
  static const pinUnlock = '/pin-unlock';
  static const home = '/home';
  static const addEditExpense = '/add-edit-expense';
  static const setBudget = '/set-budget';
  static const categories = '/categories';
  static const reports = '/reports';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        pinSetup: (_) => const PinSetupScreen(),
        pinUnlock: (_) => const PinUnlockScreen(),
        home: (_) => const HomeScreen(),
        addEditExpense: (_) => const AddEditExpenseScreen(),
        setBudget: (_) => const SetBudgetScreen(),
        categories: (_) => const CategoriesScreen(),
        reports: (_) => const ReportsScreen(),
        settings: (_) => const SettingsScreen(),
      };
}