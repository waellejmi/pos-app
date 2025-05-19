import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/models/supplier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierDetailPage extends StatefulWidget {
  final int supplierId;

  SupplierDetailPage({required this.supplierId});

  @override
  _SupplierDetailPageState createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  late Future<Supplier> _supplierFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _supplierFuture = _fetchSupplier(widget.supplierId);
  }

  Future<Supplier> _fetchSupplier(int supplierId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await _apiService.getSupplier(supplierId, token!);
      if (response.statusCode == 200) {
        final supplier = Supplier.fromJson(jsonDecode(response.body));
        return supplier;
      } else {
        throw Exception('Failed to load supplier');
      }
    } catch (e) {
      throw Exception('Error fetching supplier');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supplier Detail Page'),
      ),
      body: FutureBuilder<Supplier>(
        future: _supplierFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          } else {
            final supplier = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    supplier.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Contact: ${supplier.contactName}'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Email: ${supplier.email}'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Phone: ${supplier.phone}'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Address: ${supplier.address}'),
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: supplier.products.length,
                    itemBuilder: (context, index) {
                      final product = supplier.products[index];
                      return ListTile(
                        leading: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                            'Price: \$${product.price.toStringAsFixed(2)}'),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
