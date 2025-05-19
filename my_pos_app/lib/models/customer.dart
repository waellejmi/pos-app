class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
