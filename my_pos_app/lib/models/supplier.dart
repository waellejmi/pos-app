import 'package:my_pos_app/models/product.dart';

class Supplier {
  final int id;
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Product> products;

  Supplier({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.products,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      contactName: json['contactName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      products: json['products'] != null && json['products'] is List
          ? (json['products'] as List<dynamic>)
              .map((data) => Product.fromJson(data))
              .toList()
          : [],
    );
  }
}
