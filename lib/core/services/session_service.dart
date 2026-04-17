class SessionService {
  DateTime? _lastBackgroundTime;

  void markBackgrounded() {
    _lastBackgroundTime = DateTime.now();
  }

  bool shouldLock({required int lockAfterSeconds}) {
    if (_lastBackgroundTime == null) return false;
    final diff = DateTime.now().difference(_lastBackgroundTime!);
    return diff.inSeconds >= lockAfterSeconds;
  }

  void clear() {
    _lastBackgroundTime = null;
  }
}