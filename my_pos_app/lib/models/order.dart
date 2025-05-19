import 'package:my_pos_app/models/customer.dart';
import 'package:my_pos_app/models/orderitem.dart';
import 'package:my_pos_app/models/payment.dart';
import 'package:my_pos_app/models/user.dart';

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String comments;
  final String shippingAddress;
  final Customer? customer; // Allow customer to be nullable
  final User user;
  final Payment payment;
  final List<OrderItem> orderItems;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.comments,
    required this.shippingAddress,
    this.customer, // Nullable customer
    required this.user,
    required this.payment,
    required this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      comments: json['comments'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User(
              fullName: '',
              roleId: 0,
              email: '',
              phone: '',
              address: '',
              updatedAt: DateTime.now(),
            ),
      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'] as Map<String, dynamic>)
          : Payment(
              id: 0,
              status: '',
              paymentDate: DateTime.now(),
              paymentMethod: '',
              amount: 0.0,
              taxAmount: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      orderItems: (json['orderItems'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
