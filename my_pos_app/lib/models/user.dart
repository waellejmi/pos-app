class User {
  final String fullName;
  final int roleId;
  final String email;
  final String phone;
  final String address;
  final DateTime updatedAt;

  User({
    required this.fullName,
    required this.roleId,
    required this.email,
    required this.phone,
    required this.address,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['fullName'] ?? '',
      roleId: json['roleId'] ?? 0,
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
