import 'package:my_pos_app/models/category.dart';
import 'package:my_pos_app/models/supplier.dart';

class Product {
  final int id;
  final String name;
  final String barcode;
  final String imageUrl;
  final String description;
  final double price;
  final double discount;
  final double cost;
  final int stock;
  final int minThreshold;
  final int maxThreshold;
  final bool isActive;
  final int supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Supplier supplier;
  final Category category;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.discount,
    required this.cost,
    required this.stock,
    required this.minThreshold,
    required this.maxThreshold,
    required this.isActive,
    required this.supplierId,
    required this.createdAt,
    required this.updatedAt,
    required this.supplier,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is double) {
        return value;
      }
      return 0.0;
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      price: parseDouble(json['price']),
      discount: parseDouble(json['discount']),
      cost: parseDouble(json['cost']),
      stock: json['stock'] ?? 0,
      minThreshold: json['minThreshold'] ?? 0,
      maxThreshold: json['maxThreshold'] ?? 0,
      isActive: json['isActive'] ?? false,
      supplierId: json['supplierId'] ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      supplier: json['supplier'] != null
          ? Supplier.fromJson(json['supplier'])
          : Supplier(
              id: 0,
              name: 'Unknown',
              contactName: 'Unknown',
              email: 'Unknown',
              phone: 'Unknown',
              address: 'Unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              products: [],
            ),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : Category(
              id: 0,
              name: 'Unknown',
              description: 'Unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
  }
}
