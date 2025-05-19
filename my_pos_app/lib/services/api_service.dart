import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:my_pos_app/models/category.dart';
import 'dart:convert';
import 'package:my_pos_app/models/customer.dart';
import 'package:my_pos_app/models/supplier.dart';
import 'package:path/path.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.100.4:3333/api';

  Future<http.Response> register(String fullName, String email, String password,
      String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'fullName': fullName,
        'email': email,
        'password': password,
        'passwordConfirmation': passwordConfirmation,
      }),
    );

    return response;
  }

  Future<http.Response> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    return response;
  }

  Future<http.Response> logout(String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/logout'), // Replace with your API logout endpoint
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> getUserProfile(String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/user/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> updateUserProfile(String token,
      {String? fullName, String? phone, String? address}) async {
    final Map<String, String> body = {};

    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final response = await http.put(
      Uri.parse('$_baseUrl/user/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response;
  }

  Future<int?> fetchUserId(String token) async {
    final response = await getUserProfile(token);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      // Assume the user ID is included in the response body under the key 'id'
      return responseBody['id'] as int?;
    } else {
      print('Failed to fetch user info: ${response.statusCode}');
      return null;
    }
  }

  Future<http.Response> getProducts({
    required int page,
    String search = '',
    bool isActive = false,
    bool needsRestocking = false,
    required String token,
  }) async {
    final queryParameters = <String, String>{
      if (search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'isActive': isActive.toString(),
      'needsRestocking': needsRestocking.toString(),
    };

    final uri = Uri.parse('$_baseUrl/products')
        .replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );

    return response;
  }

  Future<http.Response> getProduct(int id, String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/products/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getOrder(int id, String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/orders/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getOrders({
    required int page,
    String search = '',
    String status = '',
    String date = '',
    required String token, // Include token here
  }) async {
    final queryParameters = <String, String>{
      if (search.isNotEmpty) 'search': search,
      if (status.isNotEmpty) 'status': status,
      if (date.isNotEmpty) 'date': date,
      'page': page.toString(),
    };

    final uri =
        Uri.parse('$_baseUrl/orders').replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );

    return response;
  }

  Future<http.Response> createOrder(
      String orderNumber,
      int paymentId,
      int? customerId,
      int userId,
      String? shippingAddress,
      String? comments,
      List<Map<String, dynamic>> orderItems,
      String paymentStatus,
      String token) async {
    String orderStatus = paymentStatus == 'Paid' ? 'Completed' : 'Pending';

    final Map<String, dynamic> orderData = {
      'orderNumber': orderNumber,
      'paymentId': paymentId,
      'customerId': customerId,
      'userId': userId,
      'completedAt':
          paymentStatus == 'Paid' ? DateTime.now().toIso8601String() : '',
      'status': orderStatus,
      'comments': comments,
      'shippingAddress': shippingAddress,
      'orderItems': orderItems,
    };

    return await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Include token in headers
      },
      body: jsonEncode(orderData),
    );
  }

  Future<http.Response> getSupplier(int id, String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/suppliers/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getSuppliers({
    required int page,
    String search = '',
    required String token, // Include token here
  }) async {
    final queryParameters = <String, String>{
      if (search.isNotEmpty) 'search': search,
      'page': page.toString(),
    };

    final uri = Uri.parse('$_baseUrl/admin/suppliers')
        .replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );

    return response;
  }

  Future<Supplier?> createSupplier(String name, String contactName,
      String email, String phone, String address, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/suppliers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include token in headers
      },
      body: jsonEncode({
        'name': name,
        'contactName': contactName,
        'email': email,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Supplier.fromJson(responseData['newSupplier']);
    } else {
      return null;
    }
  }

  Future<Supplier?> updateSupplier(
    int supplierId,
    String name,
    String contactName,
    String email,
    String phone,
    String address,
    List<int> productIds,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/suppliers/$supplierId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'contactName': contactName,
        'email': email,
        'phone': phone,
        'address': address,
        'products': productIds, // Changed from 'product_ids' to 'products'
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['supplier'] != null) {
        return Supplier.fromJson(responseBody['supplier']);
      }
    }
    return null;
  }

  Future<http.Response> deleteSupplier(int id, String token) async {
    return await http.delete(
      Uri.parse('$_baseUrl/admin/suppliers/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getCategories({
    required int page,
    String search = '',
    required String token, // Include token here
  }) async {
    final queryParameters = <String, String>{
      if (search.isNotEmpty) 'search': search,
      'page': page.toString(),
    };

    final uri = Uri.parse('$_baseUrl/admin/categories')
        .replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );

    return response;
  }

  Future<http.Response> getCategoriesForOrderPage(String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getCategory(int id, String token) async {
    return await http.get(
      Uri.parse('$_baseUrl/categories/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<Map<String, dynamic>?> createCategory(
      String name, String description, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include token in headers
      },
      body: jsonEncode({'name': name, 'description': description}),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      return responseBody['newCategory'];
    } else {
      return null;
    }
  }

  Future<Category?> updateCategory(
    int categoryId,
    String name,
    String description,
    List<int> productIds,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/categories/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'products': productIds, // Changed from 'product_ids' to 'products'
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['category'] != null) {
        return Category.fromJson(responseBody['category']);
      }
    }
    return null;
  }

  Future<http.Response> deleteCategory(int id, String token) async {
    return await http.delete(
      Uri.parse('$_baseUrl/admin/categories/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> getCustomers({
    required int page,
    String search = '',
    required String token, // Include token here
  }) async {
    final queryParameters = <String, String>{
      if (search.isNotEmpty) 'search': search,
      'page': page.toString(),
    };

    final uri = Uri.parse('$_baseUrl/customers')
        .replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );

    return response;
  }

  Future<Customer?> createCustomer(String name, String email, String phone,
      String address, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include token in headers
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Customer.fromJson(responseData['customer']);
    } else {
      return null;
    }
  }

  Future<Customer?> updateCustomer(Customer customer, String name, String email,
      String phone, String address, String token) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/customers/${customer.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      return Customer.fromJson(responseData['customer']);
    } else {
      return null;
    }
  }

  Future<http.Response> deleteCustomer(int id, String token) async {
    return await http.delete(
      Uri.parse('$_baseUrl/admin/customers/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }

  Future<http.Response> createPayment(String paymentMethod, double totalAmount,
      double taxAmount, bool isInstantDelivery, String token) async {
    String status;
    String? paymentDate;

    if (paymentMethod == 'Cash' && isInstantDelivery) {
      status = 'Paid';
      paymentDate = DateTime.now().toUtc().toIso8601String();
    } else {
      status = 'Pending';
      paymentDate = null;
    }

    final Map<String, dynamic> paymentData = {
      'status': status,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      'amount': totalAmount,
      'taxAmount': taxAmount,
    };

    return await http.post(
      Uri.parse('$_baseUrl/payments'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Include token in headers
      },
      body: jsonEncode(paymentData),
    );
  }

  Future<http.Response> createProduct({
    required String name,
    String? barcode,
    XFile? image,
    String? description,
    required double price,
    double? discount,
    required double cost,
    required int stock,
    required int minThreshold,
    int? maxThreshold,
    required bool isActive,
    required int categoryId,
    required int supplierId,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/products');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] =
          'Bearer $token'; // Include the auth token in headers

    // Add the text fields
    request.fields['name'] = name;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (description != null) request.fields['description'] = description;
    request.fields['price'] = price.toString();
    if (discount != null) request.fields['discount'] = discount.toString();
    request.fields['cost'] = cost.toString();
    request.fields['stock'] = stock.toString();
    request.fields['minThreshold'] = minThreshold.toString();
    if (maxThreshold != null) {
      request.fields['maxThreshold'] = maxThreshold.toString();
    }
    request.fields['isActive'] = isActive.toString();
    request.fields['categoryId'] = categoryId.toString();
    request.fields['supplierId'] = supplierId.toString();

    // Add the image file if provided
    if (image != null) {
      var mimeType = lookupMimeType(image.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This should match the field name expected by your backend
          image.path,
          contentType: MediaType.parse(mimeType!),
          filename: basename(image.path),
        ),
      );
    }

    // Send the request
    final response = await request.send();

    // Handle the response
    if (response.statusCode == 201) {
      return http.Response.fromStream(response); // Successfully created
    } else {
      throw Exception('Failed to create product');
    }
  }

  Future<http.Response> updateProduct({
    required int productId,
    String? name,
    String? barcode,
    XFile? image,
    String? description,
    double? price,
    double? discount,
    double? cost,
    int? stock,
    int? minThreshold,
    int? maxThreshold,
    bool? isActive,
    int? categoryId,
    int? supplierId,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/admin/products/$productId');
    var request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token';

    // Only add fields that are explicitly provided and not null
    void addFieldIfNotNull(String key, dynamic value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    }

    addFieldIfNotNull('name', name);
    addFieldIfNotNull('barcode', barcode);
    addFieldIfNotNull('description', description);
    addFieldIfNotNull('price', price);
    addFieldIfNotNull('discount', discount);
    addFieldIfNotNull('cost', cost);
    addFieldIfNotNull('stock', stock);
    addFieldIfNotNull('minThreshold', minThreshold);
    addFieldIfNotNull('maxThreshold', maxThreshold);
    addFieldIfNotNull('isActive', isActive);
    addFieldIfNotNull('categoryId', categoryId);
    addFieldIfNotNull('supplierId', supplierId);

    // Add the image file if provided
    if (image != null) {
      var mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
          filename: basename(image.path),
        ),
      );
    }

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // Handle the response
    if (response.statusCode == 201) {
      return response; // Successfully updated
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<http.Response> deleteProduct(int id, String token) async {
    return await http.delete(
      Uri.parse('$_baseUrl/admin/products/$id'),
      headers: {
        'Authorization': 'Bearer $token', // Include token in headers
      },
    );
  }
}
