import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/services/biometric_service.dart';
import '../core/services/secure_storage_service.dart';

class SecurityProvider extends ChangeNotifier {
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationSeconds = 30;

  // Current user's UID - CRITICAL for per-user PIN/biometric storage
  String? _currentUid;

  // In-memory security state for current user
  bool _pinEnabled = false;
  bool _isUnlocked = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  
  // Services
  SecureStorageService? _storage;
  BiometricService? _biometricService;
  
  // Lockout/failed attempts state
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  // Getters
  String? get currentUid => _currentUid;
  bool get pinEnabled => _pinEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  SecurityProvider(this._storage);

  void attachServices(SecureStorageService storage) {
    _storage = storage;
    _biometricService = BiometricService();
  }

  /// Load security state for a specific user
  /// Call this after login to load the logged-in user's security preferences
  /// CRITICAL: Sets _currentUid before any PIN/biometric operations
  Future<void> loadStateForUser(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[SecurityProvider] ERROR: loadStateForUser called with empty uid');
      return;
    }

    debugPrint('[SecurityProvider] Loading state for user: $uid');
    
    // CRITICAL: Set current UID FIRST
    _currentUid = uid;
    
    try {
      _pinEnabled = await _storage?.isPinEnabled(uid) ?? false;
      _isUnlocked = !_pinEnabled;
      _failedAttempts = 0;
      _lockoutUntil = null;
      
      debugPrint(
        '[SecurityProvider] User state loaded: pinEnabled=$_pinEnabled, isUnlocked=$_isUnlocked',
      );
      
      // Load biometric state for this user
      await _loadBiometricState(uid);
    } catch (e) {
      debugPrint('[SecurityProvider] ERROR loading state for user $uid: $e');
      // Don't leave in inconsistent state
      _pinEnabled = false;
      _isUnlocked = false;
      _biometricEnabled = false;
      _biometricAvailable = false;
    }
  }

  /// Load biometric availability and preference for a specific user
  Future<void> _loadBiometricState(String uid) async {
    try {
      if (uid != _currentUid) {
        debugPrint('[SecurityProvider] WARNING: loadBiometricState called with mismatched uid');
        return;
      }

      _biometricService ??= BiometricService();
      
      // Check if biometrics are available on device
      _biometricAvailable = await _biometricService!.isBiometricSupported();
      
      debugPrint('[SecurityProvider] Biometric support: $_biometricAvailable');
      
      // Load user's biometric preference
      if (_biometricAvailable) {
        _biometricEnabled = await _storage?.isBiometricEnabled(uid) ?? false;
        debugPrint('[SecurityProvider] Biometric enabled for user: $_biometricEnabled');
      } else {
        _biometricEnabled = false;
      }
    } catch (e) {
      debugPrint('[SecurityProvider] ERROR loading biometric state: $e');
      _biometricAvailable = false;
      _biometricEnabled = false;
    }
    
    notifyListeners();
  }

  /// Clear in-memory security state (but keep storage intact)
  /// Call this on logout to clear the in-memory state
  void clearInMemoryState() {
    debugPrint('[SecurityProvider] Clearing in-memory state. Previous uid: $_currentUid');
    
    _currentUid = null;
    _pinEnabled = false;
    _isUnlocked = false;
    _biometricEnabled = false;
    _biometricAvailable = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    
    // Reset biometric service plugin cache on logout
    _biometricService?.resetPluginCache();
    
    notifyListeners();
  }

  /// Set PIN for the current user
  /// CRITICAL: uid MUST match _currentUid
  Future<void> setPinForUser(String uid, String pin) async {
    if (_storage == null) {
      debugPrint('[SecurityProvider] ERROR: setPinForUser called but storage is null');
      return;
    }

    if (uid.isEmpty) {
      debugPrint('[SecurityProvider] ERROR: setPinForUser called with empty uid');
      return;
    }

    debugPrint('[SecurityProvider] Setting PIN for user: $uid (currentUid: $_currentUid)');
    
    await _storage!.savePin(uid, pin);
    await _storage!.setPinEnabled(uid, true);
    
    // Update in-memory state only if this is the current user
    if (_currentUid == uid) {
      _pinEnabled = true;
      _isUnlocked = true;
      _failedAttempts = 0;
      _lockoutUntil = null;
      debugPrint('[SecurityProvider] PIN set successfully for current user');
      notifyListeners();
    } else {
      debugPrint(
        '[SecurityProvider] WARNING: setPinForUser uid=$uid does not match currentUid=$_currentUid',
      );
    }
  }

  /// Verify PIN for the current user
  /// CRITICAL: uid MUST match _currentUid
  Future<bool> verifyPinForUser(String uid, String pin) async {
    if (_storage == null) {
      debugPrint('[SecurityProvider] ERROR: verifyPinForUser called but storage is null');
      return false;
    }

    if (uid.isEmpty) {
      debugPrint('[SecurityProvider] ERROR: verifyPinForUser called with empty uid');
      return false;
    }

    if (uid != _currentUid) {
      debugPrint(
        '[SecurityProvider] ERROR: verifyPinForUser uid=$uid does not match currentUid=$_currentUid',
      );
      return false;
    }

    // Check if temporarily locked out
    if (isLockedOut) {
      debugPrint('[SecurityProvider] PIN attempt blocked: account locked out');
      notifyListeners();
      return false;
    }

    // Auto-clear expired lockout
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
    }

    final isValid = await _storage!.verifyPin(uid, pin);
    
    if (isValid) {
      debugPrint('[SecurityProvider] PIN verified successfully for user: $uid');
      _failedAttempts = 0;
      _lockoutUntil = null;
      _isUnlocked = true;
      notifyListeners();
      return true;
    }

    // Track failed attempt
    _failedAttempts += 1;
    debugPrint('[SecurityProvider] Invalid PIN for user $uid (attempt $_failedAttempts/$_maxFailedAttempts)');
    
    // Apply lockout after max attempts
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(
        const Duration(seconds: _lockoutDurationSeconds),
      );
      debugPrint('[SecurityProvider] Account locked after $_maxFailedAttempts failed attempts');
    }

    notifyListeners();
    return false;
  }

  /// Disable PIN for a specific user
  /// CRITICAL: Also disables biometrics when PIN is disabled
  /// uid MUST match _currentUid
  Future<void> disablePinForUser(String uid) async {
    if (_storage == null) {
      debugPrint('[SecurityProvider] ERROR: disablePinForUser called but storage is null');
      return;
    }

    if (uid.isEmpty) {
      debugPrint('[SecurityProvider] ERROR: disablePinForUser called with empty uid');
      return;
    }

    debugPrint('[SecurityProvider] Disabling PIN for user: $uid (currentUid: $_currentUid)');
    
    // Disable PIN in storage
    await _storage!.setPinEnabled(uid, false);
    
    // CRITICAL: Also disable biometrics when PIN is disabled
    await _storage!.setBiometricEnabled(uid, false);
    debugPrint('[SecurityProvider] Disabled biometrics in storage for user: $uid');
    
    // Update in-memory state only if this is the current user
    if (_currentUid == uid) {
      _pinEnabled = false;
      _biometricEnabled = false;
      _isUnlocked = true;
      _failedAttempts = 0;
      _lockoutUntil = null;
      debugPrint('[SecurityProvider] PIN and biometrics disabled successfully for current user');
      notifyListeners();
    } else {
      debugPrint(
        '[SecurityProvider] WARNING: disablePinForUser uid=$uid does not match currentUid=$_currentUid',
      );
    }
  }

  /// Test biometric authentication for enrollment/setup
  /// Used when user tries to ENABLE biometrics for the first time
  /// Only requires biometrics to be available, not already enabled
  /// Does NOT unlock the app or modify security state
  /// Returns BiometricResult with success/error details
  Future<BiometricResult> authenticateForBiometricEnrollment() async {
    if (!_biometricAvailable) {
      return BiometricResult(
        success: false,
        errorCode: 'notAvailable',
        userFriendlyMessage: 'Biometric authentication is not available on this device',
      );
    }

    try {
      _biometricService ??= BiometricService();
      
      debugPrint('[SecurityProvider] Testing biometric for enrollment (not unlocking app)');
      
      final result = await _biometricService!.authenticateWithBiometrics(
        reason: 'Enable biometric unlock for your expense tracker',
        useErrorDialogs: false,
      );

      debugPrint('[SecurityProvider] Biometric enrollment test: ${result.success ? 'SUCCESS' : 'FAILED'}');
      
      // Note: We do NOT set _isUnlocked here - this is just testing biometrics
      // The actual preference will be saved by the caller after successful result
      
      return result;
    } catch (e) {
      debugPrint('[SecurityProvider] Biometric enrollment error: $e');
      return BiometricResult(
        success: false,
        errorCode: 'exception',
        userFriendlyMessage: 'An error occurred during biometric test',
      );
    }
  }

  /// Authenticate using device biometrics for normal unlock
  /// Used when app is locked and user wants to unlock with biometrics
  /// Requires biometrics to be both available AND already enabled
  /// Sets _isUnlocked = true on success
  /// Returns a BiometricResult with detailed error information
  Future<BiometricResult> authenticateWithBiometricsDetailed() async {
    if (!_biometricEnabled || !_biometricAvailable) {
      return BiometricResult(
        success: false,
        errorCode: 'notEnabled',
        userFriendlyMessage: 'Biometric authentication is not enabled',
      );
    }

    try {
      _biometricService ??= BiometricService();
      
      debugPrint('[SecurityProvider] Attempting biometric unlock');
      
      final result = await _biometricService!.authenticateWithBiometrics(
        reason: 'Unlock your expense tracker',
        useErrorDialogs: false,
      );

      if (result.success) {
        debugPrint('[SecurityProvider] Biometric unlock successful');
        _failedAttempts = 0;
        _lockoutUntil = null;
        _isUnlocked = true;
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('[SecurityProvider] Biometric unlock error: $e');
      return BiometricResult(
        success: false,
        errorCode: 'exception',
        userFriendlyMessage: 'An error occurred during authentication',
      );
    }
  }

  /// Authenticate using device biometrics (legacy method)
  /// Returns true if authentication succeeds, false otherwise
  Future<bool> authenticateWithBiometrics() async {
    final result = await authenticateWithBiometricsDetailed();
    return result.success;
  }

  /// Set biometric unlock preference for the current user
  /// If enabled, user can use biometrics to unlock instead of PIN
  Future<void> setBiometricEnabled(bool value) async {
    if (_storage == null || _currentUid == null) return;
    
    if (!_biometricAvailable) {
      return;
    }

    await _storage!.setBiometricEnabled(_currentUid!, value);
    _biometricEnabled = value;
    notifyListeners();
  }

  /// Lock the app (transition to locked state without logging out)
  /// Resets unlock state but keeps PIN settings intact
  void lock() {
    _isUnlocked = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  /// Legacy method: setPin (calls setPinForUser with current uid)
  Future<void> setPin(String pin) async {
    if (_currentUid == null) return;
    await setPinForUser(_currentUid!, pin);
  }

  /// Legacy method: verifyPin (calls verifyPinForUser with current uid)
  Future<bool> verifyPin(String pin) async {
    if (_currentUid == null) return false;
    return verifyPinForUser(_currentUid!, pin);
  }

  /// Legacy method: disablePin (calls disablePinForUser with current uid)
  Future<void> disablePin() async {
    if (_currentUid == null) return;
    await disablePinForUser(_currentUid!);
  }
}