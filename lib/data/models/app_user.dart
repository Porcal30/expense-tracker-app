class AppUser {
  final String uid;
  final String email;
  final bool pinEnabled;

  AppUser({
    required this.uid,
    required this.email,
    required this.pinEnabled,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      pinEnabled: map['pinEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'pinEnabled': pinEnabled,
    };
  }
}