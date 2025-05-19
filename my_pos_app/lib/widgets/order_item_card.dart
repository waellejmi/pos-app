import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Order Item Name'),
        subtitle: Text('Order Item Details'),
        trailing: Text('Quantity x Price'),
      ),
    );
  }
}
