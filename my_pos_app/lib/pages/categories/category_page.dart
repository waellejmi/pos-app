import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_pos_app/models/category.dart';
import 'package:my_pos_app/pages/categories/category_edit.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:my_pos_app/widgets/pagination_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryPage extends StatefulWidget {
  final bool showAddColumn;
  final bool showAdminColumns;

  CategoryPage({this.showAddColumn = false, this.showAdminColumns = false});

  @override
  _CategoryPage createState() => _CategoryPage();
}

class _CategoryPage extends State<CategoryPage> {
  List<Category> categories = [];
  List<Category> filteredCategories = [];
  String searchQuery = '';

  final ApiService _apiService = ApiService();
  Map<String, dynamic> pagination = {};
  bool isLoading = false;
  bool isAdmin = false;
  Timer? _debounce;
  int currentPage = 1; // Track the current page

  // Sorting state
  String _sortColumn = ''; // Initial sort column
  bool _isAscending = true; // Dummy data or fetched data

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAdmin = prefs.getBool('isAdmin') ?? false;
    });
  }

  Future<void> _fetchCategories({int page = 1}) async {
    if (page <= 0) return; // Prevent fetching invalid page numbers

    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      final response = await _apiService.getCategories(
          page: page, search: searchQuery, token: token!);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          final newCategories = (jsonResponse['categories']['data'] as List)
              .map((category) => Category.fromJson(category))
              .toList();

          categories = newCategories; // Replace categories with new page data

          // Apply filters and search after fetching
          filteredCategories = categories.where((category) {
            final matchesSearch =
                category.name.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          final meta =
              jsonResponse['categories']['meta'] as Map<String, dynamic>? ?? {};
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
          'Failed to load Categories: ${response.statusCode}',
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
      _fetchCategories(page: currentPage);
    });
  }

  void _sortCategories(String columnName, int columnIndex) {
    setState(() {
      if (_sortColumn == columnName) {
        _isAscending = !_isAscending; // Toggle sort direction
      } else {
        _sortColumn = columnName;
        _isAscending = true; // Default to ascending
      }

      filteredCategories.sort((a, b) {
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

  void _showCategoryDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _apiService = ApiService(); // Instantiate the service

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                final description = _descriptionController.text;

                if (name.isEmpty || description.isEmpty) {
                  // Show error if fields are empty
                  UiService.showSnackBar(
                    context,
                    'Please fill out required fields',
                    isError: true,
                  );
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');

                // Use the API service to create the category
                final newCategory =
                    await _apiService.createCategory(name, description, token!);

                if (newCategory != null) {
                  UiService.showSnackBar(
                    context,
                    'Category created successfully',
                    isError: false,
                  );
                  setState(() {
                    _fetchCategories(page: currentPage); // Initial fetch
                  });

                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  UiService.showSnackBar(
                    context,
                    'Failed to create category',
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

  void _navigateToCategoryEdit(int categoryId) async {
    // Implement edit functionality
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditPage(
          categoryId: categoryId,
        ),
      ),
    );
    if (result == true) {
      // Refresh the data or update the UI if the result is true
      setState(() {
        _fetchCategories(page: currentPage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Category',
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
                          _showCategoryDialog(context);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 24.0), // Add your desired icon here
                            SizedBox(
                                width:
                                    8.0), // Add space between the icon and text
                            Text('Add a Cateogry'),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading && categories.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredCategories.isEmpty
                    ? Center(child: Text('No categories found'))
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
                                    _sortCategories('name', columnIndex);
                                  },
                                ),
                                DataColumn(label: Text('Description')),
                                if (widget.showAddColumn)
                                  DataColumn(label: Text('Add')),
                                if (isAdmin && widget.showAdminColumns) ...[
                                  DataColumn(label: Text('Edit')),
                                ],
                              ],
                              rows: filteredCategories.map((category) {
                                final cells = [
                                  DataCell(Text(category.name)),
                                  DataCell(Text(category.description)),
                                ];

                                // Conditionally add the cell for the "Add" column
                                if (widget.showAddColumn) {
                                  cells.add(
                                    DataCell(
                                      IconButton(
                                        icon: Icon(FontAwesomeIcons.plus),
                                        onPressed: () {
                                          Navigator.pop(context, category);
                                        },
                                      ),
                                    ),
                                  );
                                }

                                // Conditionally add the cells for the "Edit" and "Delete" columns
                                if (isAdmin && widget.showAdminColumns) {
                                  cells.addAll([
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          _navigateToCategoryEdit(category.id);
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
                                  _fetchCategories(page: page);
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
