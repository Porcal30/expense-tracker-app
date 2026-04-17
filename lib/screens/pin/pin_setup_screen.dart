import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  bool _hasNavigated = false;

  Future<void> _save() async {
    final pin = _controller.text.trim();
    if (pin.length != AppConstants.pinLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN must be 4 digits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final security = context.read<SecurityProvider>();
      
      if (!auth.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final uid = auth.user!.uid;
      await security.setPinForUser(uid, pin);
      
      if (!mounted) return;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set PIN. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Icon(
                  Icons.pin_outlined,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Secure Your App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Create a 4-digit PIN to protect your data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              AppTextField(
                controller: _controller,
                label: '4-Digit PIN',
                enabled: !_isSaving,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _controller.text.length == AppConstants.pinLength
                      ? '✓ PIN valid'
                      : '${AppConstants.pinLength - _controller.text.length} digits remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _controller.text.length == AppConstants.pinLength
                            ? Colors.green
                            : Colors.grey,
                      ),
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                label: 'Continue',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: 16),
              Text(
                'You can change or disable this PIN later in Settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}