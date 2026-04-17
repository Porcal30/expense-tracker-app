import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/app_text_field.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final _controller = TextEditingController();
  String? _invalidPinMessage;
  bool _isBiometricAuthenticating = false;
  bool _hasNavigated = false;
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _tryBiometricUnlock();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Attempt to unlock with biometrics on first load if enabled
  Future<void> _tryBiometricUnlock() async {
    final provider = context.read<SecurityProvider>();
    
    // Auto-attempt biometric unlock if enabled and available
    if (provider.biometricEnabled && provider.biometricAvailable) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _unlockWithBiometrics();
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isBiometricAuthenticating || _hasNavigated) return;

    final provider = context.read<SecurityProvider>();
    
    if (!provider.biometricEnabled || !provider.biometricAvailable) {
      return;
    }

    setState(() => _isBiometricAuthenticating = true);

    try {
      final result = await provider.authenticateWithBiometricsDetailed();

      if (!mounted) return;

      if (result.success) {
        if (!_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          });
        }
      } else {
        // Show specific error but allow PIN fallback
        final message = result.userFriendlyMessage ?? 
            'Biometric authentication failed. Use PIN to unlock.';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication error. Use PIN to unlock.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBiometricAuthenticating = false);
      }
    }
  }

  Future<void> _unlock() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<SecurityProvider>();

    if (!auth.isAuthenticated) {
      debugPrint('[PinUnlockScreen] ERROR: Not authenticated');
      if (!_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        });
      }
      return;
    }

    final uid = auth.user!.uid;
    
    // CRITICAL: Verify the uid matches the current security context
    if (uid != provider.currentUid) {
      debugPrint(
        '[PinUnlockScreen] ERROR: UID mismatch! auth.uid=$uid, '
        'provider.currentUid=${provider.currentUid}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security error: User context mismatch. Please login again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Double-check lockout status
    if (provider.isLockedOut) {
      debugPrint('[PinUnlockScreen] Account is locked out');
      setState(() {
        _invalidPinMessage = null;
      });
      return;
    }

    final pin = _controller.text.trim();
    debugPrint('[PinUnlockScreen] Attempting PIN verification for user: $uid');
    
    final success = await provider.verifyPinForUser(uid, pin);

    if (!mounted) return;

    if (success) {
      debugPrint('[PinUnlockScreen] PIN verified! Navigating to home');
      if (!_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    } else {
      _controller.clear();
      final isNowLocked = provider.isLockedOut;
      
      setState(() {
        if (isNowLocked) {
          _invalidPinMessage = null;
        } else {
          _invalidPinMessage =
              'Invalid PIN (${5 - provider.failedAttempts} attempts remaining)';
        }
      });

      if (!isNowLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_invalidPinMessage ?? 'Invalid PIN')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final isLocked = security.isLockedOut;
    final remainingTime = security.remainingLockoutSeconds;
    final showBiometric = security.biometricEnabled && security.biometricAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Biometric button (if available and enabled)
              if (showBiometric) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isBiometricAuthenticating ? null : _unlockWithBiometrics,
                    icon: _isBiometricAuthenticating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(
                      _isBiometricAuthenticating
                          ? 'Authenticating...'
                          : 'Unlock with Biometrics',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'or use PIN below',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 24),
              ],
              // Lockout warning
              if (isLocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Too many failed attempts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try again in $remainingTime seconds',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red.shade700,
                            ),
                      ),
                    ],
                  ),
                )
              else ...[
                AppTextField(
                  controller: _controller,
                  label: 'Enter PIN',
                  obscureText: true,
                  enabled: !isLocked,
                ),
                if (_invalidPinMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _invalidPinMessage!,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLocked ? null : _unlock,
                  child: const Text('Unlock with PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _controller.dispose();
    super.dispose();
  }
}