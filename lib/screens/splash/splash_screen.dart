import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/security_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_hasNavigated) return;

    final auth = context.read<AuthProvider>();
    final security = context.read<SecurityProvider>();
    final expenses = context.read<ExpenseProvider>();
    final categories = context.read<CategoryProvider>();

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      debugPrint('[SplashScreen] User not authenticated, navigating to login');
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        });
      }
      return;
    }

    final uid = auth.user!.uid;
    debugPrint('[SplashScreen] Authenticated user: $uid');
    
    expenses.bindExpenses(uid);
    categories.bindCategories(uid);

    // Load security state for the current authenticated user
    // CRITICAL: This sets security._currentUid = uid
    await security.loadStateForUser(uid);
    if (!mounted) return;

    debugPrint(
      '[SplashScreen] Security state loaded. PIN enabled: ${security.pinEnabled}, '
      'Biometric available: ${security.biometricAvailable}',
    );

    if (!_hasNavigated) {
      _hasNavigated = true;
      
      // Route based on PIN state:
      // - If PIN is enabled and NOT unlocked -> go to PIN unlock
      // - Otherwise (PIN disabled OR already unlocked) -> go to HOME
      // Note: Do NOT go to pinSetup automatically
      final route = (security.pinEnabled && !security.isUnlocked)
          ? AppRoutes.pinUnlock
          : AppRoutes.home;

      debugPrint('[SplashScreen] Navigating to: $route');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, route);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your expenses...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}