import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_pos_app/models/category.dart';
import 'package:my_pos_app/models/product.dart';
import 'package:my_pos_app/pages/product/products_search_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryEditPage extends StatefulWidget {
  final int categoryId;

  const CategoryEditPage({Key? key, required this.categoryId})
      : super(key: key);

  @override
  _CategoryEditPageState createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool isLoading = true;
  Category? category;
  Product? product;
  List<Product> categoryProducts = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchCategory(widget.categoryId);
  }

  Future<void> _fetchCategory(int categoryId) async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final response = await _apiService.getCategory(categoryId, token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          category = Category.fromJson(jsonResponse);
          categoryProducts = category!.products ?? [];
          isLoading = false;
          _populateFormFields(category!);
        });
      } else {
        UiService.showSnackBar(
          context,
          'Failed to load category: ${response.statusCode}',
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

  void _populateFormFields(Category category) {
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
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
        if (!categoryProducts.any((product) => product.id == productId)) {
          await _fetchProductAndAddToCategory(productId, newFetchedProducts);
        }
      }

      setState(() {
        categoryProducts.addAll(newFetchedProducts);
        isLoading = false;
      });

      print('Updated categoryProducts: $categoryProducts');
    }
  }

  Future<void> _fetchProductAndAddToCategory(
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

  Future<void> _deleteCategory(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.deleteCategory(categoryId, token!);

      if (response.statusCode == 200) {
        // Show success message
        UiService.showSnackBar(context, 'Category deleted successfully',
            isError: false);
        // Refresh the products list after deletion
        Navigator.pop(context, true);
      } else {
        // Handle deletion failure
        UiService.showSnackBar(
            context, 'Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showDeleteConfirmation(int categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteCategory(categoryId); // Call the delete function
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
          title: Text(isLoading ? 'Loading...' : 'Edit ${category!.name}'),
          bottom: TabBar(
            labelStyle: TextStyle(color: Colors.white),
            tabs: [
              Tab(text: 'Category Details'),
              Tab(text: 'Products'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCategoryForm(),
                  _buildProductsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _saveCategory,
                  child: Text('Save Category'),
                ),
                ElevatedButton(
                  onPressed: categoryProducts.isEmpty
                      ? () => _showDeleteConfirmation(widget.categoryId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.3),
                  ),
                  child: Text('Delete Category'),
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
            'Add Products to Category',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categoryProducts.length,
            itemBuilder: (context, index) {
              final product = categoryProducts[index];
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

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');

        // Get the current list of product IDs in the category
        List<int> productIds = categoryProducts.map((p) => p.id).toList();

        final updatedCategory = await _apiService.updateCategory(
          widget.categoryId,
          _nameController.text,
          _descriptionController.text,
          productIds,
          token!,
        );

        if (updatedCategory != null) {
          UiService.showSnackBar(context, 'Category updated successfully',
              isError: false);
          Navigator.pop(context, true);
        } else {
          UiService.showSnackBar(context, 'Failed to update category');
        }
      } catch (e) {
        UiService.showSnackBar(
            context, 'An error occurred while updating the category: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
