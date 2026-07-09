class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;
  final List<String> providers;
  final Map<String, String> socialPhotoUrls;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.phoneNumber,
    this.role = 'user',
    DateTime? createdAt,
    this.providers = const [],
    this.socialPhotoUrls = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'providers': providers,
      'socialPhotoUrls': socialPhotoUrls,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      role: map['role'] as String? ?? 'user',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      providers: (map['providers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      socialPhotoUrls: (map['socialPhotoUrls'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as String)) ??
          const {},
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
    List<String>? providers,
    Map<String, String>? socialPhotoUrls,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      providers: providers ?? this.providers,
      socialPhotoUrls: socialPhotoUrls ?? this.socialPhotoUrls,
    );
  }
}
