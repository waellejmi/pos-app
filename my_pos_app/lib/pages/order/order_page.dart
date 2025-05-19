import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/order/payment/payment_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  OrderPageState createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  List<Map<String, dynamic>> _billItems = [];
  int _selectedCategoryId = 0;
  double _totalPrice = 0.0;
  double _discount = 0.0; // Discount as double
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await _apiService.getCategoriesForOrderPage(token!);
      if (response.statusCode == 200) {
        setState(() {
          _categories = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchProducts(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await _apiService.getCategory(categoryId, token!);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _products = data['products'];
          _showSearch = true; // Show the search bar when a category is selected
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      print('$error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToBill(Map<String, dynamic> product) {
    setState(() {
      final existingItem = _billItems.firstWhere(
        (item) => item['product']['id'] == product['id'],
        orElse: () =>
            {'product': product, 'quantity': 0}, // Ensure a valid default
      );

      if (existingItem['quantity'] > 0) {
        existingItem['quantity'] += 1;
      } else {
        _billItems.add({
          'product': product,
          'quantity': 1,
        });
      }
      _updateTotalPrice();
    });
  }

  void _removeFromBill(Map<String, dynamic> product) {
    setState(() {
      final itemIndex = _billItems.indexWhere(
        (item) => item['product']['id'] == product['id'],
      );

      if (itemIndex != -1) {
        // Remove the item regardless of quantity
        _billItems.removeAt(itemIndex);
        _updateTotalPrice();
      }
    });
  }

  void _reduceFromBill(Map<String, dynamic> product) {
    setState(() {
      final itemIndex = _billItems.indexWhere(
        (item) => item['product']['id'] == product['id'],
      );

      if (itemIndex != -1) {
        final item = _billItems[itemIndex];
        if (item['quantity'] > 1) {
          item['quantity'] -= 1; // Decrease quantity by 1
        } else {
          _billItems.removeAt(itemIndex); // Remove item if quantity is 1
        }
        _updateTotalPrice();
      }
    });
  }

  void _updateTotalPrice() {
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    _totalPrice = _billItems.fold(0.0, (sum, item) {
      final priceString = item['product']['price'] as String;
      final price = double.tryParse(priceString) ?? 0.0;
      final discountString = item['product']['discount'] as String?;
      final discount = double.tryParse(discountString ?? '') ?? 0.0;
      final discountedPrice = price * (1 - discount / 100); // Apply discount

      subtotal += price * item['quantity'];
      totalDiscount += (price - discountedPrice) * item['quantity'];
      return sum + discountedPrice * item['quantity'];
    });

    setState(() {
      _totalPrice = subtotal; // Update total price with subtotal
      _discount = totalDiscount; // Update total discount
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((product) {
      final name = product['name'].toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Page'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category['id'];
                              _fetchProducts(_selectedCategoryId);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Color(0xFF2D71F8), // Royal blue background
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                category['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Urbanist',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Search Bar
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Products',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                    ),
                  ),
                // Product Grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Set to 4 for four items per row
                      childAspectRatio: 0.7, // Adjust as needed
                      crossAxisSpacing: 8.0, // Adjust as needed
                      mainAxisSpacing: 8.0, // Adjust as needed
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCardWidget(
                        product: product,
                        onTap: () => _addToBill(product),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 25,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _billItems.length,
                      itemBuilder: (context, index) {
                        final item = _billItems[index];
                        final product = item['product'];
                        final quantity = item['quantity'];
                        final priceString = product['price'] as String;
                        final price = double.tryParse(priceString) ?? 0.0;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('${product['name']}'),
                                ),
                                Text(
                                  '\$${(price * quantity).toStringAsFixed(2)}', // Show original price
                                  style: const TextStyle(
                                      fontSize: 14), // Adjust font size
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    _reduceFromBill(product);
                                  },
                                ),
                                Text('$quantity'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _addToBill(product);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _removeFromBill(product);
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Less thick
                          ),
                        ),
                        Text(
                          '\$${_totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Less thick
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount:',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Less thick
                          ),
                        ),
                        Text(
                          '\$${_discount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400, // Less thick
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold, // Bold
                          ),
                        ),
                        Text(
                          '\$${(_totalPrice - _discount).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold, // Bold
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(
                              billItems: _billItems,
                              totalPrice: _totalPrice,
                              discount: _discount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      child: const Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
