import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:my_pos_app/models/customer.dart';
import 'package:my_pos_app/pages/customer/customer_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> billItems;
  final double totalPrice;
  final double discount;

  const PaymentPage({
    super.key,
    required this.billItems,
    required this.totalPrice,
    required this.discount,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _taxController = TextEditingController();
  int _selectedPaymentMethod = 0; // 0 for cash, 1 for card
  int _selectedDeliveryOption = 0;
  int _selectedCustomerToggle = 0;
  Customer? customer;
  String? _shippingAddress;
  String? _comments;
  double _totalAmount = 0.0;
  double _taxAmount = 0.0;
  String paymentMethod = 'Cash';
  bool isInstantDelivery = true;

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.totalPrice;
    final totalAmount = subtotal - widget.discount + _taxAmount;
    _totalAmount = totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutGrid(
          areas: '''
            billSummary customerInfo
            paymentInfo deliveryInfo
            paymentMethod confirmPayment
          ''',
          columnSizes: [1.fr, 1.fr],
          rowSizes: [auto, auto, auto],
          columnGap: 14,
          rowGap: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  // Adjusted height with Flexible
                  SizedBox(
                    height: 240, // Adjust height as needed
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                              label: Text('Name',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Price',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Quantity',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: widget.billItems.map((item) {
                          final product = item['product'];
                          final quantity = item['quantity'];
                          final priceString = product['price'] as String;
                          final price = double.tryParse(priceString) ?? 0.0;
                          final discountString = product['discount'] as String?;
                          final discount =
                              double.tryParse(discountString ?? '') ?? 0.0;
                          final discountedPrice = price * (1 - discount / 100);

                          return DataRow(
                            cells: [
                              DataCell(Text(product['name'])),
                              DataCell(Text(
                                  '\$${discountedPrice.toStringAsFixed(2)}')),
                              DataCell(Text(quantity.toString())),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ).inGridArea('billSummary'),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Customer Info',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  ToggleButtons(
                    isSelected: [
                      _selectedCustomerToggle == 0,
                      _selectedCustomerToggle == 1,
                      _selectedCustomerToggle == 2,
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                    fillColor: Colors.blue,
                    selectedColor: Colors.white,
                    color: Colors.black,
                    onPressed: (index) {
                      setState(() {
                        _selectedCustomerToggle = index;
                        if (_selectedCustomerToggle == 1) {
                          _navigateToCustomerPage();
                        } else if (_selectedCustomerToggle == 2) {
                          _showCustomerDialog(context);
                        }
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: const [
                            Icon(Icons.cancel, size: 40), // X icon
                            SizedBox(height: 8),
                            Text('No Customer'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: const [
                            Icon(FontAwesomeIcons.search,
                                size: 40), // Magnifying glass icon
                            SizedBox(height: 8),
                            Text('Find Customer Info'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: const [
                            Icon(Icons.add, size: 40), // Plus icon
                            SizedBox(height: 8),
                            Text('Create New Customer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Display customer info if a customer is selected or created
                  if (_selectedCustomerToggle == 1 ||
                      (_selectedCustomerToggle == 2 && customer != null))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${customer?.name ?? 'Not Available'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Email: ${customer?.email ?? 'Not Available'}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No customer selected.',
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ).inGridArea('customerInfo'),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 120,
                    child: const Text(
                      'Payment Info',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        child: TextField(
                          controller: _taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tax Amount',
                            prefixText: '\$',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _taxAmount = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 70),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
                            Text(
                                'Discount: \$${widget.discount.toStringAsFixed(2)}'),
                            Text('Tax: \$${_taxAmount.toStringAsFixed(2)}'),
                            Text('Total: \$${totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ).inGridArea('paymentInfo'),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Info',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    ToggleButtons(
                      isSelected: [
                        _selectedDeliveryOption == 0,
                        _selectedDeliveryOption == 1
                      ],
                      borderRadius: BorderRadius.circular(20.0),
                      fillColor: Colors.blue,
                      selectedColor: Colors.white,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: const [
                              Icon(FontAwesomeIcons.clock, size: 40),
                              SizedBox(height: 8),
                              Text('Instant Order'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: const [
                              Icon(FontAwesomeIcons.truck, size: 40),
                              SizedBox(height: 8),
                              Text('Shipment'),
                            ],
                          ),
                        ),
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedDeliveryOption = index;
                          if (_selectedDeliveryOption == 1) {
                            isInstantDelivery = false;
                          } else {
                            isInstantDelivery = true;
                          }
                        });

                        if (index == 1) {
                          _showShippingDialog(context);
                        }
                      },
                    ),
                  ]),
            ).inGridArea('deliveryInfo'),
            Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    ToggleButtons(
                      isSelected: [
                        _selectedPaymentMethod == 0,
                        _selectedPaymentMethod == 1
                      ],
                      borderRadius: BorderRadius.circular(20.0),
                      fillColor: Colors.blue,
                      selectedColor: Colors.white,
                      children: const [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: const [
                              Icon(FontAwesomeIcons.coins, size: 40),
                              SizedBox(height: 8),
                              Text('Cash'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: const [
                              Icon(FontAwesomeIcons.creditCard, size: 40),
                              SizedBox(height: 8),
                              Text('Card'),
                            ],
                          ),
                        ),
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedPaymentMethod = index;
                          if (_selectedPaymentMethod == 1) {
                            paymentMethod = "Card";
                          } else {
                            paymentMethod = "Cash";
                          }
                        });
                      },
                    ),
                  ],
                )).inGridArea('paymentMethod'),
            Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _showConfirmationDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16), // Increase padding
                              minimumSize: const Size(
                                  200, 50), // Set minimum size (width, height)
                              textStyle: const TextStyle(fontSize: 15),
                            ),
                            child: const Text('Confirm Payment'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).inGridArea('confirmPayment'),
          ],
        ),
      ),
    );
  }

  void _navigateToCustomerPage() async {
    final selectedCustomer = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerPage(
          showAddColumn: true,
        ), // Assuming you have a CustomerPage for this
      ),
    );

    if (selectedCustomer != null) {
      setState(() {
        customer = selectedCustomer;
      });
    } else {
      customer = null;
    }
  }

  void _showCustomerDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController =
        TextEditingController(); // New controller for phone
    final _addressController =
        TextEditingController(); // New controller for address
    final _apiService = ApiService(); // Instantiate the service

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text;
                final email = _emailController.text;
                final phone = _phoneController.text;
                final address = _addressController.text;

                if (name.isEmpty ||
                    email.isEmpty ||
                    phone.isEmpty ||
                    address.isEmpty) {
                  // Show error if fields are empty
                  UiService.showSnackBar(
                    context,
                    'Please fill out all required fields',
                    isError: true,
                  );
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');

                // Use the API service to create the customer
                final newCustomer = await _apiService.createCustomer(
                  name,
                  email,
                  phone,
                  address,
                  token!,
                );

                if (newCustomer != null) {
                  UiService.showSnackBar(
                    context,
                    'Customer created successfully',
                    isError: false,
                  );

                  Navigator.of(context).pop(); // Close the dialog

                  // Update the UI or perform actions with the newly created customer
                  setState(() {
                    customer = newCustomer;
                  });
                } else {
                  UiService.showSnackBar(
                    context,
                    'Failed to create customer',
                    isError: true,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showShippingDialog(BuildContext context) {
    // Determine the initial address value
    final String initialAddress = _shippingAddress ?? customer?.address ?? '';

    final TextEditingController _addressController = TextEditingController(
      text: initialAddress, // Use initialAddress here
    );
    final TextEditingController _commentsController = TextEditingController(
      text: _comments ?? '', // Pre-populate comments if available
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Shipping Details'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipping Address Field
                TextFormField(
                  controller: _addressController,
                  decoration:
                      const InputDecoration(labelText: 'Shipping Address'),
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Comments Field (Optional)
                TextFormField(
                  controller: _commentsController,
                  decoration:
                      const InputDecoration(labelText: 'Comments (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Extract form data
                final String address = _addressController.text.trim();
                final String comments = _commentsController.text.trim();

                // Store the form data and handle the shipping option logic
                setState(() {
                  if (_selectedDeliveryOption == 1) {
                    // Handle shipping address and comments
                    _shippingAddress = address.isNotEmpty ? address : null;
                    _comments = comments;
                  } else {
                    // Handle instant order scenario
                    _shippingAddress = null;
                    _comments = comments;
                  }
                });

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> onConfirmPayment(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      // Step 1: Create Payment
      final paymentResponse = await _apiService.createPayment(
          paymentMethod, _totalAmount, _taxAmount, isInstantDelivery, token!);

      if (paymentResponse.statusCode != 201) {
        UiService.showSnackBar(
            context, "Failed to create payment. Please try again.");
        return;
      }

      final paymentData = jsonDecode(paymentResponse.body);
      final paymentId = paymentData['payment']['id'];
      final paymentStatus = paymentData['payment']['status'];
      // Step 2: Fetch User ID and Customer ID
      final userId = await _apiService.fetchUserId(token);
      final customerId = customer?.id;

      // Step 3: Prepare Order Items
      List<Map<String, dynamic>> orderItems = widget.billItems.map((item) {
        final product = item['product'];
        final quantity = item['quantity'];
        final price = double.parse(product['price']);
        final discount = double.parse(product['discount'] ?? '0');
        final discountedPrice = price * (1 - discount / 100);

        return {
          "productId": product['id'],
          "quantity": quantity,
          "unitPrice": discountedPrice,
          "totalPrice": discountedPrice * quantity,
        };
      }).toList();

      // Step 4: Generate Order Number
      final orderNumber = await UiService.generateOrderNumber();

      // Step 5: Create Order
      final orderResponse = await _apiService.createOrder(
        orderNumber,
        paymentId,
        customerId,
        userId!,
        _shippingAddress,
        _comments,
        orderItems,
        paymentStatus,
        token,
      );

      if (orderResponse.statusCode != 201) {
        UiService.showSnackBar(
            context, "Failed to create order. Please try again.");
        return;
      }
      // Show success message
      UiService.showSnackBar(context, "Order has been successfully placed!",
          isError: false);

      // Navigate back to the previous screen or to an order confirmation page
      Navigator.of(context).pop();
    } catch (e) {
      print('Error in onConfirmPayment: $e');
      UiService.showSnackBar(context, "An error occurred: $e");
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
              'Are you sure you want to confirm the payment of \$${_totalAmount.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await onConfirmPayment(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
