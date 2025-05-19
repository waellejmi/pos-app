class Role {
  final int id;
  final String roleName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Role({
    required this.id,
    required this.roleName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      roleName: json['roleName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
