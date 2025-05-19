import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/models/user.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_pos_app/services/api_service.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  String? _newFullName;
  String? _newPhone;
  String? _newAddress;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token != null) {
        final response = await _apiService.getUserProfile(token);

        if (response.statusCode == 200) {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _user = User.fromJson(jsonResponse);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load user data: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No auth token found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token != null) {
        final response = await _apiService.logout(token);

        if (response.statusCode == 200) {
          await prefs.remove('authToken');
          await prefs.setBool('isAdmin', false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        } else {
          UiService.showSnackBar(
              context, 'Logout failed: ${response.statusCode}');
        }
      } else {
        UiService.showSnackBar(context, 'No auth token found');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 1:
        return 'Worker';
      case 2:
        _setAdminStatus(roleId);
        return 'Admin';
      default:
        return 'Unknown Role';
    }
  }

  Future<void> _setAdminStatus(int roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', true);
  }

  Future<void> _editField(String field) async {
    String? currentValue = field == 'fullName'
        ? _user?.fullName
        : field == 'phone'
            ? _user?.phone
            : _user?.address;

    String? newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? tempValue = currentValue;
        return AlertDialog(
          title: Text('Edit ${field.capitalize()}'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: "Enter new $field"),
            onChanged: (value) {
              tempValue = value;
            },
            controller: TextEditingController(text: currentValue),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('SAVE'),
              onPressed: () => Navigator.of(context).pop(tempValue),
            ),
          ],
        );
      },
    );

    if (newValue != null && newValue != currentValue) {
      setState(() {
        if (field == 'fullName') {
          _newFullName = newValue;
        } else if (field == 'phone') {
          _newPhone = newValue;
        } else if (field == 'address') {
          _newAddress = newValue;
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token != null) {
        final response = await _apiService.updateUserProfile(
          token,
          fullName: _newFullName,
          phone: _newPhone,
          address: _newAddress,
        );

        if (response.statusCode == 201) {
          UiService.showSnackBar(context, 'Profile updated successfully',
              isError: false);
          _loadUserProfile(); // Reload the profile
        } else {
          UiService.showSnackBar(
              context, 'Failed to update profile: ${response.statusCode}');
        }
      } else {
        UiService.showSnackBar(context, 'No auth token found');
      }
    } catch (e) {
      UiService.showSnackBar(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!))
            else if (_user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditableRow(
                      'Full Name',
                      _newFullName ?? _user!.fullName,
                      () => _editField('fullName')),
                  _buildInfoRow('Email', _user!.email),
                  _buildEditableRow('Phone', _newPhone ?? _user!.phone,
                      () => _editField('phone')),
                  _buildEditableRow('Address', _newAddress ?? _user!.address,
                      () => _editField('address')),
                  _buildInfoRow('Role', _getRoleName(_user!.roleId)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text('Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            Spacer(),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.grey,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Retrieve SharedPreferences instance
                final prefs = await SharedPreferences.getInstance();

                // Get the authToken (for potential use, like logging out on server side)
                final token = prefs.getString('authToken');

                // Remove the authToken
                await prefs.remove('authToken');

                // Set isAdmin to false
                await prefs.setBool('isAdmin', false);

                // Navigate to LoginPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Go to Login Page'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(
              child: Text(value.isNotEmpty ? value : '',
                  style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(
              child: Text(value.isNotEmpty ? value : '',
                  style: TextStyle(fontSize: 18))),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
