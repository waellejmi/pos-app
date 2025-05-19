import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_pos_app/models/category.dart';
import 'package:my_pos_app/models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_pos_app/models/supplier.dart';
import 'dart:io';

import 'package:my_pos_app/pages/categories/category_page.dart';
import 'package:my_pos_app/pages/supplier/supplier_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateOrEditProductPage extends StatefulWidget {
  final int? productId;

  const CreateOrEditProductPage({Key? key, this.productId}) : super(key: key);

  @override
  _CreateOrEditProductPageState createState() =>
      _CreateOrEditProductPageState();
}

class _CreateOrEditProductPageState extends State<CreateOrEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minThresholdController = TextEditingController();
  final _maxThresholdController = TextEditingController();

  bool _isActive = true;
  bool isLoading = false;
  int _selectedSupplierToggle = 0;
  int _selectedCategoryToggle = 0;
  XFile? _image;
  Category? category;
  Category? _selectedCategory;
  Supplier? _selectedSupplier;
  Supplier? supplier;
  final ApiService _apiService = ApiService();
  Product? product;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _fetchProduct(widget.productId!);
    }
  }

  void _populateFormFields(Product product) {
    _nameController.text = product.name;
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toString();
    _discountController.text = product.discount?.toString() ?? '';
    _costController.text = product.cost.toString();
    _stockController.text = product.stock.toString();
    _minThresholdController.text = product.minThreshold.toString();
    _maxThresholdController.text = product.maxThreshold?.toString() ?? '';
    _isActive = product.isActive;
  }

  Future<void> _fetchProduct(int productId) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      UiService.showSnackBar(context, 'Authentication token not found.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await _apiService.getProduct(productId, token);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          product = Product.fromJson(jsonResponse);

          isLoading = false;
          _populateFormFields(product!);
        });
      } else {
        UiService.showSnackBar(
          context,
          'Failed to load product: ${response.statusCode}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product == null ? 'Create Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Column: Text Fields
              Flexible(
                flex: 1, // Takes half of the available space
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      'Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        } else if (value.length < 3 || value.length > 255) {
                          return 'Name must be between 3 and 255 characters';
                        }
                        return null;
                      },
                      isOptional: false,
                    ),
                    _buildTextField(_barcodeController, 'Barcode',
                        isOptional: true),
                    _buildTextField(_descriptionController, 'Description',
                        isOptional: true),
                    _buildNumericField(_priceController, 'Price'),
                    _buildNumericField(_costController, 'Cost'),
                    _buildNumericField(_stockController, 'Stock'),
                    _buildNumericField(
                        _minThresholdController, 'Min Threshold'),
                    _buildNumericField(_maxThresholdController, 'Max Threshold',
                        isOptional: true),
                    _buildNumericField(_discountController, 'Discount',
                        isOptional: true),
                    SwitchListTile(
                      title: Text(
                        'Is Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Second Column: Image Picker, Category Selector, Supplier Selector
              Flexible(
                flex: 1, // Takes half of the available space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildImagePicker(),
                    SizedBox(height: 36),
                    _buildCategorySelector(),
                    SizedBox(height: 36),
                    // Display category info if a category is selected or if product is being edited
                    if (_selectedCategoryToggle == 1 ||
                        (_selectedCategoryToggle == 0 &&
                            (product?.category != null || category != null)))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category : ${_selectedCategory?.name ?? product?.category?.name ?? 'None'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 56),
                    _buildSupplierSelector(),
                    SizedBox(height: 36),
                    // Display supplier info if a supplier is selected
                    if (_selectedSupplierToggle == 1 ||
                        (_selectedSupplierToggle == 0 &&
                            (product?.supplier != null || supplier != null)))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier : ${_selectedSupplier?.name ?? product?.supplier?.name ?? 'None'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 56),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16), // Increase padding
                        minimumSize: const Size(
                            200, 50), // Set minimum size (width, height)
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _showConfirmationDialog(context);
                        }
                      },
                      child: Text(product == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile; // Assign XFile directly
      });
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Product Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null // If a new image is selected
                ? Image.file(
                    File(_image!.path), // Display the selected image
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  )
                : product?.imageUrl != null
                    ? Image.network(
                        product!.imageUrl,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Show a placeholder if the image fails to load
                          return Container(
                            height: 150,
                            width: 150,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Container(
                        // If no image is selected and no existing image URL
                        height: 150,
                        width: 150,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                        ),
                      ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_a_photo, size: 34, color: Colors.blue),
              onPressed: _chooseImage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Urbanist',
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isOptional ? null : 'This field is required';
          }
          return validator?.call(value);
        },
      ),
    );
  }

  Widget _buildNumericField(
    TextEditingController controller,
    String label, {
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Urbanist',
          ),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isOptional ? null : 'This field is required';
          }
          final numValue = num.tryParse(value);
          if (numValue == null || numValue < 0) {
            return 'Enter a valid number greater than or equal to 0';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supplier Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        SizedBox(height: 10),
        ToggleButtons(
          isSelected: [
            _selectedSupplierToggle == 0,
            _selectedSupplierToggle == 1,
          ],
          borderRadius: BorderRadius.circular(8.0),
          fillColor: Colors.blue,
          selectedColor: Colors.white,
          color: Colors.black,
          onPressed: (index) {
            setState(() {
              _selectedSupplierToggle = index;
              // Add logic for supplier selection
              if (_selectedSupplierToggle == 1) {
                _navigateToSupplierPage();
              } else if (_selectedSupplierToggle == 0) {
                _showSupplierDialog(context);
              }
            });
          },
          children: [
            _buildToggleChild(Icons.add, 'Create New Supplier'),
            _buildToggleChild(
                FontAwesomeIcons.magnifyingGlass, 'Find Supplier'),
          ],
        ),
        // Add supplier info display here
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        SizedBox(height: 10),
        ToggleButtons(
          isSelected: [
            _selectedCategoryToggle == 0,
            _selectedCategoryToggle == 1,
          ],
          borderRadius: BorderRadius.circular(8.0),
          fillColor: Colors.blue,
          selectedColor: Colors.white,
          color: Colors.black,
          onPressed: (index) {
            setState(() {
              _selectedCategoryToggle = index;
              if (_selectedCategoryToggle == 1) {
                _navigateToCategoryPage();
              } else if (_selectedCategoryToggle == 0) {
                _showCategoryDialog(context);
              }
            });
          },
          children: [
            _buildToggleChild(Icons.add, 'Create New Category'),
            _buildToggleChild(
                FontAwesomeIcons.magnifyingGlass, 'Find Category'),
          ],
        ),
        // Add category
      ],
    );
  }

  Widget _buildToggleChild(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Icon(icon, size: 40),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
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

                  Navigator.of(context).pop(); // Close the dialog

                  // Update the UI or perform actions with the newly created category
                  setState(() {
                    _selectedCategory = Category.fromJson(
                        newCategory); // Assuming Category.fromJson() is available
                  });
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

  void _showSupplierDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _contactNameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _addressController = TextEditingController();
    final _apiService = ApiService(); // Instantiate the service

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

                // Use the API service to create the supplier
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

                  Navigator.of(context).pop(); // Close the dialog

                  // Update the UI or perform actions with the newly created supplier
                  setState(() {
                    _selectedSupplier = newSupplier;
                  });
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

  void _navigateToCategoryPage() async {
    final selectedCategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPage(
          showAddColumn: true,
        ), // Assuming you have a CustomerPage for this
      ),
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategory = selectedCategory;
      });
    }
  }

  void _navigateToSupplierPage() async {
    final selectedSupplier = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierPage(showAddColumn: true),
      ),
    );

    if (selectedSupplier != null) {
      setState(() {
        _selectedSupplier = selectedSupplier;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    category = _selectedCategory;
    supplier = _selectedSupplier;

    try {
      if (product == null) {
        // If there's no product, create a new one
        await _createProduct(token!);
      } else {
        // If the product exists, update it
        await _updateProduct(token!, product!.id);
      }
    } catch (error) {
      print('Error submitting product: $error');
      UiService.showSnackBar(context, 'Error submitting product');
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Creation'),
          content: Text(
              'Are you sure you want to confirm the creation of this product? '),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _handleSubmit(); // Perform the confirmation action
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProduct(String token) async {
    final response = await _apiService.createProduct(
      name: _nameController.text,
      barcode: _barcodeController.text,
      image: _image,
      description: _descriptionController.text,
      price: double.parse(_priceController.text),
      cost: double.parse(_costController.text),
      discount: _discountController.text.isNotEmpty
          ? double.parse(_discountController.text)
          : null,
      stock: int.parse(_stockController.text),
      minThreshold: int.parse(_minThresholdController.text),
      maxThreshold: _maxThresholdController.text.isNotEmpty
          ? int.parse(_maxThresholdController.text)
          : null,
      isActive: _isActive,
      categoryId: category!.id,
      supplierId: supplier!.id,
      token: token,
    );

    if (response.statusCode == 201) {
      // Handle success
      UiService.showSnackBar(context, 'Product created successfully',
          isError: false);
      Navigator.of(context).pop(true); // Pass a true value indicating success
    } else {
      // Handle failure
      UiService.showSnackBar(context, 'Failed to create product');
    }
  }

  Future<void> _updateProduct(String token, int productId) async {
    try {
      final response = await _apiService.updateProduct(
        productId: productId,
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        barcode:
            _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
        image: _image,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        cost: _costController.text.isNotEmpty
            ? double.parse(_costController.text)
            : null,
        discount: _discountController.text.isNotEmpty
            ? double.parse(_discountController.text)
            : null,
        stock: _stockController.text.isNotEmpty
            ? int.parse(_stockController.text)
            : null,
        minThreshold: _minThresholdController.text.isNotEmpty
            ? int.parse(_minThresholdController.text)
            : null,
        maxThreshold: _maxThresholdController.text.isNotEmpty
            ? int.parse(_maxThresholdController.text)
            : null,
        isActive: _isActive,
        categoryId: category?.id,
        supplierId: supplier?.id,
        token: token,
      );

      if (response.statusCode == 201) {
        // Handle success
        UiService.showSnackBar(context, 'Product updated successfully',
            isError: false);
        Navigator.of(context).pop(true); // Pass a true value indicating success
      } else {
        // Handle unexpected status code
        UiService.showSnackBar(
            context, 'Unexpected response: ${response.statusCode}');
      }
    } catch (e) {
      // Handle failure
      UiService.showSnackBar(context, 'Failed to update product: $e');
    }
  }
}
