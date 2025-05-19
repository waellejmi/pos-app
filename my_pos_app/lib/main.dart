import 'package:flutter/material.dart';
import 'package:my_pos_app/pages/auth/login_page.dart'; // Update with your actual path
import 'package:my_pos_app/pages/home/home_page.dart'; // Update with your actual path
import 'package:shared_preferences/shared_preferences.dart';

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
        fontFamily: 'Urbanist', // Set the default font to Urbanist
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF2D71F8), foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor:
                const Color(0xFF2D71F8), // Royal blue background for buttons
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(
                0xFF2D71F8), // Royal blue background for text buttons
          ),
        ),
      ),
      home: isLoggedIn ? HomePage() : LoginPage(),
    );
  }
}
