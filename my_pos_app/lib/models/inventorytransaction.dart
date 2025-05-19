

class InventoryTransaction {
  final int id;
  final int productId;
  final int inventoryId;
  final String transactionType; // e.g., purchase, sale, adjustment
  final int quantity;
  final DateTime transactionDate;
  final DateTime createdAt;

  InventoryTransaction({
    required this.id,
    required this.productId,
    required this.inventoryId,
    required this.transactionType,
    required this.quantity,
    required this.transactionDate,
    required this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'],
      productId: json['productId'],
      inventoryId: json['inventoryId'],
      transactionType: json['transactionType'],
      quantity: json['quantity'],
      transactionDate: DateTime.parse(json['transactionDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
