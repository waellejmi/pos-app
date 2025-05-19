import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/supplier/supplier_detail_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _productFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProduct(widget.productId);
  }

  Future<Product> _fetchProduct(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await _apiService.getProduct(id, token!);
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Product Details'),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          } else {
            final product = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      product.imageUrl,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${product.name}',
                              style: Theme.of(context).textTheme.headlineSmall),
                          SizedBox(height: 8.0),
                          Text('Barcode: ${product.barcode}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          SizedBox(height: 8.0),
                          Text('Description: ${product.description}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Price: \$${product.price}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          SizedBox(height: 8.0),
                          Text('Discount: ${product.discount}%',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Cost: \$${product.cost}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Stock: ${product.stock}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          SizedBox(height: 8.0),
                          Text('Min Threshold: ${product.minThreshold}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Max Threshold: ${product.maxThreshold}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Active: ${product.isActive ? 'Yes' : 'No'}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          SizedBox(height: 8.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SupplierDetailPage(
                                      supplierId: product.supplier.id),
                                ),
                              );
                            },
                            child: Text('Supplier: ${product.supplier.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    )),
                          ),
                          SizedBox(height: 8.0),
                          Text('Category:',
                              style: Theme.of(context).textTheme.bodyLarge),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '- ${product.category.name}: ${product.category.description}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text('Created At: ${product.createdAt.toLocal()}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 8.0),
                          Text('Updated At: ${product.updatedAt.toLocal()}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
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
}
