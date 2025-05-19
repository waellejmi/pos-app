import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/models/order.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import your ApiService

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  OrderDetailPage({required this.orderId});

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<Order> _orderFuture;
  final ApiService _apiService = ApiService();

  Future<Order> _fetchOrder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await _apiService.getOrder(id, token!);
    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load order');
    }
  }

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          } else {
            final order = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Details
                  _buildSectionTitle('Order Details'),
                  Card(
                    child: ListTile(
                      title: Text('Order Number: ${order.orderNumber}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${order.status.capitalize()}'),
                          Text('Shipping Address: ${order.shippingAddress}'),
                          Text('Comments: ${order.comments}'),
                          Text('Created At: ${_formatDate(order.createdAt)}'),
                          Text('Updated At: ${_formatDate(order.updatedAt)}'),
                          if (order.completedAt != null)
                            Text(
                                'Completed At: ${_formatDate(order.completedAt!)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),

                  // Customer Information
                  _buildSectionTitle('Customer Information'),
                  Card(
                    child: ListTile(
                      title: order.customer != null
                          ? Text(order.customer!.name)
                          : Text('No customer information available'),
                      subtitle: order.customer != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.customer?.email != null)
                                  Text('Email: ${order.customer!.email}'),
                                if (order.customer?.phone != null)
                                  Text('Phone: ${order.customer!.phone}'),
                                if (order.customer?.address != null)
                                  Text('Address: ${order.customer!.address}'),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const Divider(),

                  // User Information
                  _buildSectionTitle('Processed By'),
                  Card(
                    child: ListTile(
                      title: Text(order.user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${order.user.email}'),
                          Text('Phone: ${order.user.phone}'),
                          Text('Address: ${order.user.address}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),

                  // Payment Details
                  _buildSectionTitle('Payment Details'),
                  Card(
                    child: ListTile(
                      title: Text(
                          'Payment Status: ${order.payment.status.capitalize()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Method: ${order.payment.paymentMethod.capitalize()}'),
                          Text('Amount: \$${order.payment.amount}'),
                          Text('Tax Amount: \$${order.payment.taxAmount}'),
                          if (order.payment.paymentDate != null)
                            Text(
                                'Payment Date: ${_formatDate(order.payment.paymentDate!)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),

                  // Order Items
                  _buildSectionTitle('Order Items'),
                  Card(
                    child: Column(
                      children: order.orderItems.map((item) {
                        return ListTile(
                          title: Text('Product ID: ${item.productId}'),
                          subtitle: Text('Quantity: ${item.quantity}'),
                          trailing: Text('Total Price: \$${item.totalPrice}'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}

// Extension method to capitalize strings
extension StringCasingExtension on String {
  String capitalize() =>
      this.length > 0 ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}
