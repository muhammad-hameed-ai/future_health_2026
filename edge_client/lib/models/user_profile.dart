/// Authenticated User Profile for SkinGuard UAE & Malaffi HIE.
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String avatarData;
  final String role;
  final String? accessToken;
  final bool isRemembered;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarData = '',
    this.role = 'citizen',
    this.accessToken,
    this.isRemembered = true,
    this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatarData,
    String? role,
    String? accessToken,
    bool? isRemembered,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email, // Email is locked by design
      avatarData: avatarData ?? this.avatarData,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      isRemembered: isRemembered ?? this.isRemembered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'avatar_data': avatarData,
        'role': role,
        'access_token': accessToken,
        'is_remembered': isRemembered,
        'created_at': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Authorized User',
      email: json['email'] ?? '',
      avatarData: json['avatar_data'] ?? '',
      role: json['role'] ?? 'citizen',
      accessToken: json['access_token'],
      isRemembered: json['is_remembered'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
