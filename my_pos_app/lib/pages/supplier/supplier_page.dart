import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_pos_app/models/supplier.dart';
import 'package:my_pos_app/pages/supplier/supplier_edit.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:my_pos_app/widgets/pagination_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierPage extends StatefulWidget {
  final bool showAddColumn;
  final bool showAdminColumns;

  SupplierPage({this.showAddColumn = false, this.showAdminColumns = false});

  @override
  _SupplierPage createState() => _SupplierPage();
}

class _SupplierPage extends State<SupplierPage> {
  List<Supplier> suppliers = [];
  List<Supplier> filteredSuppliers = [];
  String searchQuery = '';
  final ApiService _apiService = ApiService();
  Map<String, dynamic> pagination = {};
  bool isLoading = false;
  bool isAdmin = false;
  Timer? _debounce;
  int currentPage = 1;

  String _sortColumn = '';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAdmin = prefs.getBool('isAdmin') ?? false;
    });
  }

  Future<void> _fetchSuppliers({int page = 1}) async {
    if (page <= 0) return;

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.getSuppliers(
          page: page, search: searchQuery, token: token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          final newSuppliers = (jsonResponse['suppliers']['data'] as List)
              .map((supplier) => Supplier.fromJson(supplier))
              .toList();

          suppliers = newSuppliers;

          filteredSuppliers = suppliers.where((supplier) {
            final matchesSearch =
                supplier.name.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          final meta =
              jsonResponse['suppliers']['meta'] as Map<String, dynamic>? ?? {};
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
          'Failed to load Suppliers: ${response.statusCode}',
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
        currentPage = 1;
      });
      _fetchSuppliers(page: currentPage);
    });
  }

  void _sortSuppliers(String columnName, int columnIndex) {
    setState(() {
      if (_sortColumn == columnName) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = columnName;
        _isAscending = true;
      }

      filteredSuppliers.sort((a, b) {
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

  void _showSupplierDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _contactNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _addressController = TextEditingController();
    final _apiService = ApiService();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _contactNameController,
                decoration: const InputDecoration(labelText: 'Contact Name'),
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
                final contactName = _contactNameController.text;
                final email = _emailController.text;
                final phone = _phoneController.text;
                final address = _addressController.text;

                if (name.isEmpty ||
                    contactName.isEmpty ||
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

                final newSupplier = await _apiService.createSupplier(
                  name,
                  contactName,
                  email,
                  phone,
                  address,
                  token!,
                );

                if (newSupplier != null) {
                  UiService.showSnackBar(
                    context,
                    'Supplier created successfully',
                    isError: false,
                  );
                  setState(() {
                    _fetchSuppliers(page: currentPage);
                  });
                  Navigator.of(context).pop();
                } else {
                  UiService.showSnackBar(
                    context,
                    'Failed to create supplier',
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

  void _navigateToSupplierEdit(int supplierId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierEditPage(
          supplierId: supplierId,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _fetchSuppliers(page: currentPage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suppliers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Supplier',
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
                          _showSupplierDialog(context);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 24.0),
                            SizedBox(width: 8.0),
                            Text('Add a Supplier'),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading && suppliers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredSuppliers.isEmpty
                    ? Center(child: Text('No suppliers found'))
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
                                    _sortSuppliers('name', columnIndex);
                                  },
                                ),
                                DataColumn(label: Text('Contact Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('Address')),
                                if (widget.showAddColumn)
                                  DataColumn(label: Text('Add')),
                                if (isAdmin && widget.showAdminColumns) ...[
                                  DataColumn(label: Text('Edit')),
                                ],
                              ],
                              rows: filteredSuppliers.map((supplier) {
                                final cells = [
                                  DataCell(Text(supplier.name)),
                                  DataCell(Text(supplier.contactName)),
                                  DataCell(Text(supplier.email)),
                                  DataCell(Text(supplier.phone)),
                                  DataCell(Text(supplier.address)),
                                ];

                                if (widget.showAddColumn) {
                                  cells.add(
                                    DataCell(
                                      IconButton(
                                        icon: Icon(FontAwesomeIcons.plus),
                                        onPressed: () {
                                          Navigator.pop(context, supplier);
                                        },
                                      ),
                                    ),
                                  );
                                }

                                if (isAdmin && widget.showAdminColumns) {
                                  cells.addAll([
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          _navigateToSupplierEdit(supplier.id);
                                        },
                                      ),
                                    ),
                                  ]);
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
                                  _fetchSuppliers(page: page);
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
