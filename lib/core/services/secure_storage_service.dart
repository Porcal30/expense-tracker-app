import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Key generators for UID-scoped storage
  String _pinHashKey(String uid) => 'user_pin_hash_$uid';
  String _pinEnabledKey(String uid) => 'pin_enabled_$uid';
  String _biometricEnabledKey(String uid) => 'biometric_enabled_$uid';

  /// Save PIN hash for a specific user
  /// CRITICAL: Each user has a separate key in secure storage
  Future<void> savePin(String uid, String pin) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: savePin called with empty uid');
      return;
    }

    final pinHash = _hashPin(pin);
    final key = _pinHashKey(uid);
    
    debugPrint('[SecureStorageService] Saving PIN hash for user: $uid (key: $key)');
    await _storage.write(key: key, value: pinHash);
  }

  /// Verify PIN for a specific user
  /// CRITICAL: Retrieves hash for specific user only
  Future<bool> verifyPin(String uid, String enteredPin) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: verifyPin called with empty uid');
      return false;
    }

    final key = _pinHashKey(uid);
    final savedHash = await _storage.read(key: key);
    
    if (savedHash == null) {
      debugPrint('[SecureStorageService] No PIN found for user: $uid (key: $key)');
      return false;
    }
    
    final enteredHash = _hashPin(enteredPin);
    final match = enteredHash == savedHash;
    
    debugPrint(
      '[SecureStorageService] PIN verification for user $uid: ${match ? 'MATCH' : 'MISMATCH'}',
    );
    
    return match;
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    return sha256.convert(pin.codeUnits).toString();
  }

  /// Set PIN enabled flag for a specific user
  Future<void> setPinEnabled(String uid, bool value) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: setPinEnabled called with empty uid');
      return;
    }

    final key = _pinEnabledKey(uid);
    debugPrint('[SecureStorageService] Setting PIN enabled=$value for user: $uid (key: $key)');
    await _storage.write(key: key, value: value.toString());
  }

  /// Check if PIN is enabled for a specific user
  Future<bool> isPinEnabled(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: isPinEnabled called with empty uid');
      return false;
    }

    final key = _pinEnabledKey(uid);
    final value = await _storage.read(key: key);
    final result = value == 'true';
    
    debugPrint('[SecureStorageService] PIN enabled for user $uid: $result (key: $key)');
    
    return result;
  }

  /// Set biometric enabled flag for a specific user
  Future<void> setBiometricEnabled(String uid, bool value) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: setBiometricEnabled called with empty uid');
      return;
    }

    final key = _biometricEnabledKey(uid);
    debugPrint('[SecureStorageService] Setting biometric enabled=$value for user: $uid (key: $key)');
    await _storage.write(key: key, value: value.toString());
  }

  /// Check if biometric is enabled for a specific user
  Future<bool> isBiometricEnabled(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: isBiometricEnabled called with empty uid');
      return false;
    }

    final key = _biometricEnabledKey(uid);
    final value = await _storage.read(key: key);
    final result = value == 'true';
    
    debugPrint('[SecureStorageService] Biometric enabled for user $uid: $result (key: $key)');
    
    return result;
  }

  /// Clear all security data for a specific user
  /// CRITICAL: Only deletes data for the specified user
  Future<void> clearSecurityData(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[SecureStorageService] ERROR: clearSecurityData called with empty uid');
      return;
    }

    debugPrint('[SecureStorageService] Clearing all security data for user: $uid');
    
    await _storage.delete(key: _pinHashKey(uid));
    await _storage.delete(key: _pinEnabledKey(uid));
    await _storage.delete(key: _biometricEnabledKey(uid));
  }
}