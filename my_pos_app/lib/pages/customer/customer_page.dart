import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_pos_app/models/customer.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:my_pos_app/widgets/pagination_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerPage extends StatefulWidget {
  final bool showAddColumn;
  final bool showAdminColumns;

  CustomerPage({this.showAddColumn = false, this.showAdminColumns = false});

  @override
  _CustomerPage createState() => _CustomerPage();
}

class _CustomerPage extends State<CustomerPage> {
  List<Customer> customers = [];
  List<Customer> filteredcustomers = [];
  String searchQuery = '';
  bool showActiveOnly = true;
  bool showRestockingOnly = false;
  final ApiService _apiService = ApiService();
  Map<String, dynamic> pagination = {};
  bool isLoading = false;
  Timer? _debounce;
  int currentPage = 1; // Track the current page
  bool isAdmin = false; // Admin status

  // Sorting state
  String _sortColumn = ''; // Initial sort column
  bool _isAscending = true; // Dummy data or fetched data

  @override
  void initState() {
    super.initState();
    _fetchCustomers(); // Fetch initial data
    _checkAdminStatus(); // Check if the user is an admin
  }

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAdmin = prefs.getBool('isAdmin') ?? false;
    });
  }

  Future<void> _fetchCustomers({int page = 1}) async {
    if (page <= 0) return; // Prevent fetching invalid page numbers

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.getCustomers(
          page: page, search: searchQuery, token: token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          final newCustomers = (jsonResponse['customers']['data'] as List)
              .map((customer) => Customer.fromJson(customer))
              .toList();

          customers = newCustomers; // Replace customers with new page data

          // Apply filters and search after fetching
          filteredcustomers = customers.where((customer) {
            final matchesSearch =
                customer.name.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          final meta =
              jsonResponse['customers']['meta'] as Map<String, dynamic>? ?? {};
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
          'Failed to load Customers: ${response.statusCode}',
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
      _fetchCustomers(page: currentPage);
    });
  }

  void _sortCustomers(String columnName, int columnIndex) {
    setState(() {
      if (_sortColumn == columnName) {
        _isAscending = !_isAscending; // Toggle sort direction
      } else {
        _sortColumn = columnName;
        _isAscending = true; // Default to ascending
      }

      filteredcustomers.sort((a, b) {
        int compareResult;
        if (columnName == 'name') {
          compareResult = a.name.compareTo(b.name);
        } else {
          return 0;
        }

        return _isAscending ? compareResult : -compareResult;
      });
    });
  }

  void _showDeleteConfirmation(int customerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this customer?'),
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
                _deleteCustomer(customerId); // Call the delete function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.deleteCustomer(customerId, token!);

      if (response.statusCode == 200) {
        UiService.showSnackBar(context, 'Customer deleted successfully',
            isError: false);
        _fetchCustomers(page: currentPage); // Refresh the customer list
      } else {
        UiService.showSnackBar(context,
            'Failed to delete customer: ${response.statusCode} and ${response.body}');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
    final _nameController = TextEditingController(text: customer?.name ?? '');
    final _emailController = TextEditingController(text: customer?.email ?? '');
    final _phoneController = TextEditingController(text: customer?.phone ?? '');
    final _addressController =
        TextEditingController(text: customer?.address ?? '');
    final _apiService = ApiService(); // Instantiate the service

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(customer == null ? 'Create New Customer' : 'Edit Customer'),
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
                  UiService.showSnackBar(
                    context,
                    'Please fill out all required fields',
                    isError: true,
                  );
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');

                if (customer == null) {
                  // Create new customer
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
                  } else {
                    UiService.showSnackBar(
                      context,
                      'Failed to create customer',
                      isError: true,
                    );
                  }
                } else {
                  try {
                    await _apiService.updateCustomer(
                      customer,
                      name,
                      email,
                      phone,
                      address,
                      token!,
                    );
                    UiService.showSnackBar(
                      context,
                      'Customer updated successfully',
                      isError: false,
                    );
                  } catch (e) {
                    UiService.showSnackBar(
                      context,
                      'Failed to update customer ',
                      isError: true,
                    );
                  }
                }

                Navigator.of(context).pop(); // Close the dialog

                // Refresh the customer list
                setState(() {
                  _fetchCustomers(page: currentPage);
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Customer',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAdmin && widget.showAdminColumns)
                      ElevatedButton(
                        onPressed: () {
                          _showCustomerDialog(context);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 24.0), // Add your desired icon here
                            SizedBox(
                                width:
                                    8.0), // Add space between the icon and text
                            Text('Add a Customer'),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading && customers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredcustomers.isEmpty
                    ? Center(child: Text('No customers found'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            DataTable(
                              sortColumnIndex: 1,
                              sortAscending: _isAscending,
                              columns: [
                                DataColumn(
                                  label: Text('Name'),
                                  onSort: (columnIndex, _) {
                                    _sortCustomers('name', columnIndex);
                                  },
                                ),
                                DataColumn(
                                  label: Text('Email'),
                                ),
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('Address')),
                                if (widget.showAddColumn)
                                  DataColumn(label: Text('Add')),
                                if (isAdmin && widget.showAdminColumns)
                                  DataColumn(
                                      label: Text('Edit')), // Admin only column
                                if (isAdmin && widget.showAdminColumns)
                                  DataColumn(
                                      label:
                                          Text('Delete')), // Admin only column
                              ],
                              rows: filteredcustomers.map((customer) {
                                final cells = [
                                  DataCell(Text(customer.name)),
                                  DataCell(Text(customer.email)),
                                  DataCell(Text(customer.phone.toString())),
                                  DataCell(Text(customer.address.toString())),
                                ];
                                // Conditionally add the cell for the "Add" column
                                if (widget.showAddColumn) {
                                  cells.add(
                                    DataCell(
                                      IconButton(
                                        icon: Icon(FontAwesomeIcons.plus),
                                        onPressed: () {
                                          Navigator.pop(context, customer);
                                        },
                                      ),
                                    ),
                                  );
                                }

                                // Conditionally add cells for "Edit" and "Delete" (Admin only)
                                if (isAdmin && widget.showAdminColumns) {
                                  cells.add(
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          // Navigate to the edit page or handle edit logic
                                          _showCustomerDialog(context,
                                              customer: customer);
                                        },
                                      ),
                                    ),
                                  );
                                  cells.add(
                                    DataCell(
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Color(0xFFFF4500),
                                        ),
                                        onPressed: () {
                                          _showDeleteConfirmation(customer
                                              .id); // Show confirmation dialog
                                        },
                                      ),
                                    ),
                                  );
                                }

                                return DataRow(cells: cells);
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
                                  _fetchCustomers(page: page);
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
