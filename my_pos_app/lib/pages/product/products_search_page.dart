import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/product/product_create_or_edit.dart';
import 'package:my_pos_app/widgets/filter_button.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/models/product.dart';
import 'dart:convert';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:my_pos_app/pages/product/product_detail_page.dart';
import 'package:my_pos_app/widgets/pagination_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsPage extends StatefulWidget {
  final bool showAddColumn;
  final bool showAdminColumns;
  final int? categoryId;

  ProductsPage(
      {this.showAddColumn = false,
      this.showAdminColumns = false,
      this.categoryId});
  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<int> selectedProductIds = [];
  String searchQuery = '';
  bool showActiveOnly = true;
  bool showRestockingOnly = false;
  final ApiService _apiService = ApiService();
  Map<String, dynamic> pagination = {};
  bool isLoading = false;
  Timer? _debounce;
  int currentPage = 1; // Track the current page
  bool isAdmin = false; // New variable to track admin status

  // Sorting state
  String _sortColumn = ''; // Initial sort column
  bool _isAscending = true; // Initial sort direction

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Initial fetch
    _checkAdminStatus(); // Check admin status
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAdmin = prefs.getBool('isAdmin') ?? false;
    });
  }

  Future<void> _fetchProducts({int page = 1}) async {
    if (page <= 0) return; // Prevent fetching invalid page numbers

    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.getProducts(
          page: page,
          search: searchQuery,
          isActive: showActiveOnly,
          needsRestocking: showRestockingOnly,
          token: token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          final newProducts = (jsonResponse['products']['data'] as List)
              .map((product) => Product.fromJson(product))
              .toList();

          products = newProducts; // Replace products with new page data

          // Apply filters and search after fetching
          filteredProducts = products.where((product) {
            final matchesSearch =
                product.name.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          final meta =
              jsonResponse['products']['meta'] as Map<String, dynamic>? ?? {};
          pagination = {
            'current_page': meta['currentPage'] ?? 1,
            'last_page': meta['lastPage'] ?? 1,
          };

          currentPage = pagination['current_page'];

          isLoading = false;
        });
      } else {
        UiService.showSnackBar(
          context,
          'Failed to load products: ${response.statusCode}',
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(Duration(seconds: 1), () {
      setState(() {
        searchQuery = query;
        currentPage = 1; // Reset to page 1 on new search
      });
      _fetchProducts(page: currentPage);
    });
  }

  void _toggleActiveOnly() {
    setState(() {
      showActiveOnly = !showActiveOnly;
      currentPage = 1; // Reset to page 1 when filter changes
      _fetchProducts(page: currentPage);
    });
  }

  void _toggleRestockingOnly() {
    setState(() {
      showRestockingOnly = !showRestockingOnly;
      currentPage = 1; // Reset to page 1 when filter changes
      _fetchProducts(page: currentPage);
    });
  }

  void _navigateToProductDetail(int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: productId),
      ),
    );
  }

  void _navigateToProductEdit(int productId) async {
    // Implement edit functionality
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOrEditProductPage(
          productId: productId,
        ),
      ),
    );
    if (result == true) {
      // Refresh the data or update the UI if the result is true
      setState(() {
        _fetchProducts(page: currentPage); // Initial fetch
      });
    }
  }

  void _navigateToProductCreate() async {
    // Implement edit functionality
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOrEditProductPage(),
      ),
    );
    if (result == true) {
      // Refresh the data or update the UI if the result is true
      setState(() {
        _fetchProducts(page: currentPage); // Initial fetch
      });
    }
  }

  void _sortProducts(String columnName) {
    setState(() {
      if (_sortColumn == columnName) {
        _isAscending = !_isAscending; // Toggle sort direction
      } else {
        _sortColumn = columnName;
        _isAscending = true; // Default to ascending
      }

      filteredProducts.sort((a, b) {
        int compareResult;
        if (columnName == 'name') {
          compareResult = a.name.compareTo(b.name);
        } else if (columnName == 'supplier') {
          compareResult = a.supplier.name.compareTo(b.supplier.name);
        } else {
          return 0;
        }

        return _isAscending ? compareResult : -compareResult;
      });
    });
  }

  Future<void> _deleteProduct(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.deleteProduct(productId, token!);

      if (response.statusCode == 200) {
        // Show success message
        UiService.showSnackBar(context, 'Product deleted successfully',
            isError: false);
        // Refresh the products list after deletion
        _fetchProducts(page: currentPage);
      } else {
        // Handle deletion failure
        UiService.showSnackBar(
            context, 'Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showDeleteConfirmation(int productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this product?'),
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
                _deleteProduct(productId); // Call the delete function
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Products',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterButton(
                      label: 'Active Only',
                      isActive: showActiveOnly,
                      color: Colors.green,
                      onPressed: _toggleActiveOnly,
                    ),
                    FilterButton(
                      label: 'Restocking',
                      isActive: showRestockingOnly,
                      color: Colors.green,
                      onPressed: _toggleRestockingOnly,
                    ),
                    if (isAdmin && widget.showAdminColumns)
                      ElevatedButton(
                        onPressed: () {
                          _navigateToProductCreate();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 24.0), // Add your desired icon here
                            SizedBox(
                                width:
                                    8.0), // Add space between the icon and text
                            Text('Create Product'),
                          ],
                        ),
                      )
                    else if (isAdmin && widget.showAddColumn)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, selectedProductIds.toList());
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 24.0), // Add your desired icon here
                            SizedBox(
                                width:
                                    8.0), // Add space between the icon and text
                            Text('Add Products'),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading && products.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(child: Text('No products found'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            DataTable(
                              sortColumnIndex: _sortColumn == 'name'
                                  ? 1
                                  : _sortColumn == 'supplier'
                                      ? 2
                                      : null,
                              sortAscending: _isAscending,
                              columns: [
                                if (widget.showAddColumn && isAdmin)
                                  DataColumn(label: Text('Select')),
                                DataColumn(label: Text('')),
                                DataColumn(
                                  label: Text('Name'),
                                  onSort: (columnIndex, _) {
                                    _sortProducts('name');
                                  },
                                ),
                                DataColumn(
                                    label: Text('Supplier'),
                                    onSort: (columnIndex, _) {
                                      _sortProducts('supplier');
                                    }),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Min Threshold')),
                                DataColumn(label: Text('Active')),
                                DataColumn(label: Text('Details')),
                                if (isAdmin & widget.showAdminColumns)
                                  DataColumn(label: Text('Edit')),
                                if (isAdmin & widget.showAdminColumns)
                                  DataColumn(label: Text('Delete')),
                              ],
                              rows: filteredProducts.map((product) {
                                Color rowColor;

                                if (product.stock < product.minThreshold) {
                                  rowColor = Colors.red.withOpacity(0.2);
                                } else if (showRestockingOnly &&
                                    product.stock - product.minThreshold < 10) {
                                  rowColor = Colors.yellow.withOpacity(0.2);
                                } else {
                                  rowColor = Colors.transparent;
                                }

                                return DataRow(
                                  color: WidgetStateProperty.all(rowColor),
                                  cells: [
                                    if (widget.showAddColumn && isAdmin)
                                      DataCell(
                                        Checkbox(
                                          value: selectedProductIds
                                              .contains(product.id),
                                          onChanged: (bool? value) {
                                            _toggleProductSelection(product.id);
                                          },
                                        ),
                                      ),
                                    DataCell(
                                      CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(product.imageUrl),
                                      ),
                                    ),
                                    DataCell(Text(product.name)),
                                    DataCell(Text(product.supplier.name)),
                                    DataCell(Text(product.stock.toString())),
                                    DataCell(
                                        Text(product.minThreshold.toString())),
                                    DataCell(
                                        Text(product.isActive ? 'Yes' : 'No')),
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.more_horiz),
                                        onPressed: () {
                                          _navigateToProductDetail(product.id);
                                        },
                                      ),
                                    ),
                                    if (isAdmin && widget.showAdminColumns)
                                      DataCell(
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _navigateToProductEdit(product.id);
                                          },
                                        ),
                                      ),
                                    if (isAdmin && widget.showAdminColumns)
                                      DataCell(
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Color(0xFFFF4500),
                                          onPressed: () {
                                            _showDeleteConfirmation(product.id);
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16.0),
                            PaginationWidget(
                              currentPage: pagination['current_page'] ?? 1,
                              lastPage: pagination['last_page'] ?? 1,
                              onPageChanged: (page) {
                                if (page != currentPage) {
                                  setState(() {
                                    currentPage = page;
                                  });
                                  _fetchProducts(page: page);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
