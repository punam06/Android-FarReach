/// Domain entity representing a signed-in user (matches `publicUser` on the server).
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? profilePic;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePic,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'user').toString(),
        profilePic: json['profile_pic']?.toString(),
      );
}

