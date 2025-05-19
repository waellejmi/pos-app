import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/home/home_page.dart';
import 'dart:convert';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final ApiService _apiService = ApiService();

  Future<void> _register() async {
    final fullName = _fullNameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty) {
      UiService.showSnackBar(context, 'All fields are required', isError: true);
      return;
    }

    if (password != passwordConfirmation) {
      UiService.showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    try {
      final response = await _apiService.register(
          fullName, email, password, passwordConfirmation);

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final token = responseData['token']; // Extract the token

          // Save the token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);

          UiService.showSnackBar(context, 'Registration successful!',
              isError: false);

          // Navigate to the HomePage
          Future.delayed(Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage()), // Redirect to HomePage directly
            );
          });
        } catch (e) {
          UiService.showSnackBar(context, 'Failed to decode JSON: $e',
              isError: true);
        }
      } else {
        UiService.showSnackBar(context,
            'Registration failed: ${response.statusCode} ${response.body}',
            isError: true);
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _passwordConfirmationController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
