import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiService {
  static Future<void> showSnackBar(BuildContext context, String message,
      {bool isError = true}) async {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Future<String> generateOrderNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';

    int count = prefs.getInt(dateKey) ?? 0;
    count++;
    prefs.setInt(dateKey, count);

    final orderNumber = 'ORD${count.toString().padLeft(4, '0')}';
    return orderNumber;
  }
}
