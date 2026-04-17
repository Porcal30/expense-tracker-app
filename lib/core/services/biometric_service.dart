import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool? _pluginAvailable;

  // Error codes from local_auth
  static const String _notAvailable = 'NotAvailable';
  static const String _notEnrolled = 'NotEnrolled';
  static const String _lockedOut = 'LockedOut';
  static const String _permanentlyLockedOut = 'PermanentlyLockedOut';
  static const String _biometricOnlyNotSupported = 'BiometricOnlyNotSupported';
  static const String _pluginNotFound = 'PluginNotFound';

  /// Check if the local_auth plugin is available
  /// Caches the result to avoid repeated expensive checks
  Future<bool> _isPluginAvailable() async {
    if (_pluginAvailable != null) {
      return _pluginAvailable!;
    }

    try {
      // Try a simple method call to verify plugin is loaded
      await _localAuth.canCheckBiometrics;
      _pluginAvailable = true;
      debugPrint('[BiometricService] Plugin: Available ✓');
      return true;
    } on MissingPluginException catch (e) {
      _pluginAvailable = false;
      debugPrint('[BiometricService] Plugin: MISSING - $e');
      return false;
    } on PlatformException catch (e) {
      // Some platform exceptions indicate plugin is there but device doesn't support biometrics
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        _pluginAvailable = true;
        debugPrint('[BiometricService] Plugin: Available, but device limitation: ${e.code}');
        return true;
      }
      _pluginAvailable = false;
      debugPrint('[BiometricService] Plugin: Error during check - ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      _pluginAvailable = false;
      debugPrint('[BiometricService] Plugin: Unknown error - $e');
      return false;
    }
  }

  /// Reset plugin cache (useful for testing or after Android lifecycle changes)
  void resetPluginCache() {
    _pluginAvailable = null;
    debugPrint('[BiometricService] Plugin cache reset');
  }

  /// Logs debug information about biometric support
  Future<void> _debugLogBiometricInfo() async {
    if (!kDebugMode) return;

    try {
      final pluginOk = await _isPluginAvailable();
      if (!pluginOk) {
        debugPrint('[BiometricService] Debug: Plugin not available, skipping detailed checks');
        return;
      }

      final isSupported = await isBiometricSupported();
      final canCheck = await isBiometricAvailable();
      final biometrics = await getAvailableBiometrics();

      debugPrint(
        '[BiometricService] Device Support: isSupported=$isSupported, '
        'canCheckBiometrics=$canCheck, availableBiometrics=$biometrics',
      );
    } catch (e) {
      debugPrint('[BiometricService] Error logging device info: $e');
    }
  }

  /// Check if the device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final pluginOk = await _isPluginAvailable();
      if (!pluginOk) {
        return false;
      }

      final result = await _localAuth.canCheckBiometrics;
      debugPrint('[BiometricService] canCheckBiometrics: $result');
      return result;
    } on MissingPluginException {
      _pluginAvailable = false;
      debugPrint('[BiometricService] canCheckBiometrics: MissingPluginException');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final pluginOk = await _isPluginAvailable();
      if (!pluginOk) {
        return [];
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('[BiometricService] Available biometrics: $biometrics');
      return biometrics;
    } on MissingPluginException {
      _pluginAvailable = false;
      debugPrint('[BiometricService] getAvailableBiometrics: MissingPluginException');
      return [];
    } catch (e) {
      debugPrint('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometrics are available and supported
  Future<bool> isBiometricSupported() async {
    try {
      final pluginOk = await _isPluginAvailable();
      if (!pluginOk) {
        debugPrint('[BiometricService] isBiometricSupported: Plugin not available');
        return false;
      }

      final available = await isBiometricAvailable();
      final biometrics = await getAvailableBiometrics();
      final supported = available && biometrics.isNotEmpty;
      debugPrint(
        '[BiometricService] isBiometricSupported: $supported '
        '(available=$available, biometrics=${biometrics.length})',
      );
      return supported;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric support: $e');
      return false;
    }
  }


  /// Authenticate using device biometrics
  /// Returns BiometricResult with success status and optional error details
  Future<BiometricResult> authenticateWithBiometrics({
    required String reason,
    bool useErrorDialogs = false,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
  }) async {
    try {
      await _debugLogBiometricInfo();

      // Check plugin availability first
      final pluginOk = await _isPluginAvailable();
      if (!pluginOk) {
        return BiometricResult(
          success: false,
          errorCode: _pluginNotFound,
          userFriendlyMessage: 'Biometric service unavailable. Use PIN instead.',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: useErrorDialogs,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );

      if (authenticated) {
        debugPrint('[BiometricService] Authentication succeeded');
        return BiometricResult(
          success: true,
          errorCode: null,
          userFriendlyMessage: null,
        );
      }

      // User cancelled or failed
      debugPrint('[BiometricService] User cancelled authentication or failed');
      return BiometricResult(
        success: false,
        errorCode: 'userCancelled',
        userFriendlyMessage: 'Biometric authentication cancelled',
      );
    } on MissingPluginException catch (e) {
      _pluginAvailable = false;
      debugPrint('[BiometricService] MissingPluginException during auth: $e');
      return BiometricResult(
        success: false,
        errorCode: _pluginNotFound,
        userFriendlyMessage: 'Biometric service unavailable. Use PIN instead.',
      );
    } on PlatformException catch (e) {
      debugPrint(
        '[BiometricService] PlatformException: code=${e.code}, message=${e.message}',
      );
      return _handlePlatformException(e);
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error during authentication: $e');
      return BiometricResult(
        success: false,
        errorCode: 'unknown',
        userFriendlyMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Handle PlatformException and return user-friendly message
  BiometricResult _handlePlatformException(PlatformException e) {
    final code = e.code;

    // Map local_auth error codes to user-friendly messages
    if (code == _notAvailable) {
      return BiometricResult(
        success: false,
        errorCode: code,
        userFriendlyMessage: 'Biometric authentication is not available',
      );
    } else if (code == _notEnrolled) {
      return BiometricResult(
        success: false,
        errorCode: code,
        userFriendlyMessage:
            'No biometric data enrolled. Please add a fingerprint or face in device settings.',
      );
    } else if (code == _lockedOut) {
      return BiometricResult(
        success: false,
        errorCode: code,
        userFriendlyMessage:
            'Biometric is temporarily locked. Please try again later or use PIN.',
      );
    } else if (code == _permanentlyLockedOut) {
      return BiometricResult(
        success: false,
        errorCode: code,
        userFriendlyMessage:
            'Biometric is permanently locked. Please use your PIN to unlock.',
      );
    } else if (code == _biometricOnlyNotSupported) {
      return BiometricResult(
        success: false,
        errorCode: code,
        userFriendlyMessage: 'Biometric-only authentication is not supported',
      );
    }

    // Generic message for other errors
    return BiometricResult(
      success: false,
      errorCode: code,
      userFriendlyMessage:
          'Biometric authentication failed (${e.code}). Please try again or use PIN.',
    );
  }

  /// Stop any ongoing authentication if possible
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      debugPrint('[BiometricService] Authentication stopped');
    } catch (e) {
      debugPrint('[BiometricService] Error stopping authentication: $e');
    }
  }
}

/// Result of biometric authentication with error details
class BiometricResult {
  final bool success;
  final String? errorCode;
  final String? userFriendlyMessage;

  BiometricResult({
    required this.success,
    this.errorCode,
    this.userFriendlyMessage,
  });

  @override
  String toString() =>
      'BiometricResult(success=$success, errorCode=$errorCode, message=$userFriendlyMessage)';
}
