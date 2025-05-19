import 'package:flutter/material.dart';
import 'package:my_pos_app/services/api_service.dart'; // Update with your actual path
import 'package:my_pos_app/pages/auth/register_page.dart'; // Update with your actual path
import 'package:my_pos_app/pages/home/home_page.dart'; // Import the HomePage
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert'; // Import to decode the response JSON

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My POS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? HomePage() : LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Initialize your API service
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkForToken();
  }

  Future<void> _checkForToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token != null) {
        // Token exists, navigate to HomePage directly
        _navigateToHome();
      } else {
        // No token found, stay on login page or handle as needed
        print('No token found, staying on login page.');
      }
    } catch (e) {
      print('Error checking for token: $e');
      // Handle the error (e.g., show an error message to the user)
    }
  }

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      UiService.showSnackBar(context, 'Please fill in both fields');
      return;
    }

    try {
      final response = await _apiService.login(email, password);

      if (response.statusCode == 200) {
        // Handle successful login
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('authToken', token);
        if (_rememberMe) {}
        UiService.showSnackBar(context, 'Login successful', isError: false);
        _navigateToHome();
      } else {
        // Handle errors from the server
        UiService.showSnackBar(context, 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other issues
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  void _navigateToHome() {
    // Navigate to the HomePage
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage()), // Redirect to HomePage directly
      );
    });
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 600), // Limit width for tablets/desktops
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Email',
                    style: Theme.of(context).textTheme.headlineMedium),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your email',
                  ),
                ),
                SizedBox(height: 16),
                Text('Password',
                    style: Theme.of(context).textTheme.headlineMedium),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your password',
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    Text('Remember Me'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
