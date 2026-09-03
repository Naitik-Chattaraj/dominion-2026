class LocalUser {
  final String uid;
  final String name;
  final String email;
  final String passwordHash;
  final String publicUid;
  final String pairingCode;
  final bool biometricEnabled;
  final bool staySignedIn;

  LocalUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.publicUid,
    required this.pairingCode,
    this.biometricEnabled = false,
    this.staySignedIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'publicUid': publicUid,
      'pairingCode': pairingCode,
      'biometricEnabled': biometricEnabled ? 1 : 0,
      'staySignedIn': staySignedIn ? 1 : 0,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      publicUid: map['publicUid'] as String,
      pairingCode: map['pairingCode'] as String,
      biometricEnabled: (map['biometricEnabled'] as int) == 1,
      staySignedIn: (map['staySignedIn'] as int) == 1,
    );
  }
}
