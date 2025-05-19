

class ProductCategory {
  final int id;
  final int productId;
  final int categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCategory({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      productId: json['productId'],
      categoryId: json['categoryId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
