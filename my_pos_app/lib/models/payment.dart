class Payment {
  final int id;
  final String status;
  final DateTime? paymentDate;
  final String paymentMethod;
  final double amount;
  final double taxAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.status,
    this.paymentDate,
    required this.paymentMethod,
    required this.amount,
    required this.taxAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      amount: double.tryParse(json['amount'] as String? ?? '0.0') ?? 0.0,
      taxAmount: double.tryParse(json['taxAmount'] as String? ?? '0.0') ?? 0.0,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
