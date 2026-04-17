import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/security_provider.dart';
import '../pin/pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasNavigated = false;

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Capture providers
    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final securityProvider = context.read<SecurityProvider>();

    await authProvider.logout();
    expenseProvider.clear();
    categoryProvider.clear();
    securityProvider.clearInMemoryState();

    if (!mounted) return;

    if (!_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        }
      });
    }
  }

  Future<void> _togglePinProtection(bool newValue, SecurityProvider security) async {
    final auth = context.read<AuthProvider>();
    
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = auth.user!.uid;

    if (newValue && !security.pinEnabled) {
      // Enable PIN - navigate to setup
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreenWrapper()),
      ).then((_) {
        // Refresh UI after PIN setup completes
        if (mounted) setState(() {});
      });
    } else if (!newValue && security.pinEnabled) {
      // Disable PIN - show confirmation
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable PIN Protection'),
          content: const Text('Are you sure you want to disable PIN protection?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await security.disablePinForUser(uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN protection disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool newValue, SecurityProvider security) async {
    if (!security.biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrics are not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newValue) {
      // Try to authenticate first before enabling
      try {
        final result = await security.authenticateWithBiometricsDetailed();
        
        if (!mounted) return;
        
        if (result.success) {
          // Only save biometric preference if authentication succeeds
          await security.setBiometricEnabled(true);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric unlock enabled'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show specific error reason
          final message = result.userFriendlyMessage ?? 
              'Biometric authentication failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enable biometric unlock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Disable biometric
      await security.setBiometricEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric unlock disabled'),
          backgroundColor: Colors.orange,
        ),
      );
      // Refresh UI
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Security',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SwitchListTile(
              value: security.pinEnabled,
              onChanged: (value) => _togglePinProtection(value, security),
              title: const Text('PIN Protection'),
              subtitle: security.pinEnabled
                  ? const Text('Active - PIN required when app resumes')
                  : const Text('Tap to enable PIN protection'),
            ),
          ),
          if (security.biometricAvailable)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SwitchListTile(
                value: security.biometricEnabled,
                onChanged: (value) => _toggleBiometric(value, security),
                title: const Text('Use Biometrics to Unlock'),
                subtitle: security.biometricEnabled
                    ? const Text('Active - Use fingerprint or device biometrics')
                    : const Text('Tap to enable biometric unlock'),
              ),
            ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.lock,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Lock App Now'),
              subtitle: const Text('Lock the app without logging out'),
              onTap: () {
                security.lock();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App locked'),
                    backgroundColor: Colors.blue,
                  ),
                );
                Navigator.pushReplacementNamed(context, AppRoutes.pinUnlock);
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red.shade700,
              ),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              onTap: _showLogoutConfirmation,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Wrapper widget to ensure PIN setup properly updates parent state
class PinSetupScreenWrapper extends StatelessWidget {
  const PinSetupScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const PinSetupScreen();
  }
}