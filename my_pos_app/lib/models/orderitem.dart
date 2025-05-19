class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: double.tryParse(json['unitPrice'] as String? ?? '0.0') ?? 0.0,
      totalPrice:
          double.tryParse(json['totalPrice'] as String? ?? '0.0') ?? 0.0,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
