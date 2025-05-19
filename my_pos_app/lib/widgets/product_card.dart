import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/product/product_detail_page.dart';
import 'package:my_pos_app/widgets/fltr_product_card.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ProductCardWidget({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert price to double
    double price = 0.0;
    if (product['price'] is String) {
      price = double.tryParse(product['price']) ?? 0.0;
    } else if (product['price'] is double) {
      price = product['price'];
    } else if (product['price'] is int) {
      price = product['price'].toDouble();
    }
    double discount = 0.0;
    if (product['discount'] is String) {
      discount = double.tryParse(product['discount']) ?? 0.0;
    } else if (product['discount'] is double) {
      discount = product['discount'];
    } else if (product['discount'] is int) {
      discount = product['discount'].toDouble();
    }

    double? discountfinal = (discount > 20.00) ? discount : null;

    // Define product properties
    final productName = product['name'] ?? 'Product Name';
    final imageUrl = product['imageUrl'] ?? '';
    final stock = product['stock'] ?? 0;
    final productId = product['id'] ?? 0;

    return ProductCard(
        productName: productName,
        imageUrl: imageUrl,
        price: price,
        quantity: stock,
        stock: stock,
        discountPercentage: discountfinal,
        onTap: onTap,
        onDetailsPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productId: productId),
            ),
          );
          // Pass the product ID
        });
  }
}
