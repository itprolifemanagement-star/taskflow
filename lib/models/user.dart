class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? department;
  final String role; // 'admin' | 'user'
  final String? profilePhoto;
  final String status;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.department,
    required this.role,
    this.profilePhoto,
    this.status = 'active',
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: int.parse(json['id'].toString()),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'],
      role: json['role'] ?? 'user',
      profilePhoto: json['profile_photo'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'department': department,
        'role': role,
        'profile_photo': profilePhoto,
        'status': status,
      };
}
