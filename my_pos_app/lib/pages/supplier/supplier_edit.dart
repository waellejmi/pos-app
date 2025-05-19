import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_pos_app/models/supplier.dart';
import 'package:my_pos_app/models/product.dart';
import 'package:my_pos_app/pages/product/products_search_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierEditPage extends StatefulWidget {
  final int supplierId;

  const SupplierEditPage({Key? key, required this.supplierId})
      : super(key: key);

  @override
  _SupplierEditPageState createState() => _SupplierEditPageState();
}

class _SupplierEditPageState extends State<SupplierEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool isLoading = true;
  Supplier? supplier;
  List<Product> supplierProducts = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchSupplier(widget.supplierId);
  }

  Future<void> _fetchSupplier(int supplierId) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final response = await _apiService.getSupplier(supplierId, token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          supplier = Supplier.fromJson(jsonResponse);
          supplierProducts = supplier!.products ?? [];
          isLoading = false;
          _populateFormFields(supplier!);
        });
      } else {
        UiService.showSnackBar(
          context,
          'Failed to load supplier: ${response.statusCode}',
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _populateFormFields(Supplier supplier) {
    _nameController.text = supplier.name;
    _contactNameController.text = supplier.contactName;
    _emailController.text = supplier.email;
    _phoneController.text = supplier.phone;
    _addressController.text = supplier.address;
  }

  void _navigateToAddProducts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsPage(
          showAddColumn: true,
          showAdminColumns: false,
        ),
      ),
    );

    if (result != null && result is List<int>) {
      setState(() {
        isLoading = true;
      });

      List<Product> newFetchedProducts = [];

      for (int productId in result) {
        if (!supplierProducts.any((product) => product.id == productId)) {
          await _fetchProductAndAddToSupplier(productId, newFetchedProducts);
        }
      }

      setState(() {
        supplierProducts.addAll(newFetchedProducts);
        isLoading = false;
      });

      print('Updated supplierProducts: $supplierProducts');
    }
  }

  Future<void> _fetchProductAndAddToSupplier(
      int productId, List<Product> fetchedProducts) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      UiService.showSnackBar(context, 'Authentication token not found.');
      return;
    }

    try {
      final response = await _apiService.getProduct(productId, token);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final product = Product.fromJson(jsonResponse);
        fetchedProducts.add(product);
      } else {
        UiService.showSnackBar(
          context,
          'Failed to load product: ${response.statusCode}',
        );
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<void> _deleteSupplier(int supplierId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.deleteSupplier(supplierId, token!);

      if (response.statusCode == 200) {
        UiService.showSnackBar(context, 'Supplier deleted successfully',
            isError: false);
        Navigator.pop(context, true);
      } else {
        UiService.showSnackBar(
            context, 'Failed to delete supplier: ${response.statusCode}');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showDeleteConfirmation(int supplierId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this supplier?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSupplier(supplierId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isLoading ? 'Loading...' : 'Edit ${supplier!.name}'),
          bottom: TabBar(
            labelStyle: TextStyle(color: Colors.white),
            tabs: [
              Tab(text: 'Supplier Details'),
              Tab(text: 'Products'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildSupplierForm(),
                  _buildProductsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildSupplierForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Supplier Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a supplier name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _contactNameController,
              decoration: InputDecoration(labelText: 'Contact Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _saveSupplier,
                  child: Text('Save Category'),
                ),
                ElevatedButton(
                  onPressed: supplierProducts.isEmpty
                      ? () => _showDeleteConfirmation(widget.supplierId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.3),
                  ),
                  child: Text('Delete Supplier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _navigateToAddProducts,
          child: Text(
            'Add Products to Supplier',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: supplierProducts.length,
            itemBuilder: (context, index) {
              final product = supplierProducts[index];
              return ListTile(
                leading: product.imageUrl != null
                    ? Image.network(product.imageUrl!,
                        width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.image_not_supported),
                title: Text(product.name),
                subtitle: Text(product.description ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');

        // Get the current list of product IDs associated with the supplier
        List<int> currentProductIds =
            supplierProducts.map((p) => p.id).toList();

        // Get the original list of product IDs (before any deletions)
        List<int> originalProductIds =
            supplier!.products!.map((p) => p.id).toList();

        // Find products that were deleted (in original list but not in current list)
        List<int> deletedProductIds = originalProductIds
            .where((id) => !currentProductIds.contains(id))
            .toList();

        // Add deleted product IDs to the current list with null supplierId
        List<int> updatedProductIds = [
          ...currentProductIds,
          ...deletedProductIds
        ];

        final updatedSupplier = await _apiService.updateSupplier(
          widget.supplierId,
          _nameController.text,
          _contactNameController.text,
          _emailController.text,
          _phoneController.text,
          _addressController.text,
          updatedProductIds,
          token!,
        );

        if (updatedSupplier != null) {
          UiService.showSnackBar(context, 'Supplier updated successfully',
              isError: false);
          Navigator.pop(context, true);
        } else {
          UiService.showSnackBar(context, 'Failed to update supplier');
        }
      } catch (e) {
        UiService.showSnackBar(
            context, 'An error occurred while updating the supplier: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
