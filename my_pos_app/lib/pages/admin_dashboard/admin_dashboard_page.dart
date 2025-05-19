import 'package:flutter/material.dart';
import 'package:my_pos_app/models/product.dart';
import 'package:my_pos_app/pages/categories/category_page.dart';
import 'package:my_pos_app/pages/customer/customer_page.dart';
import 'package:my_pos_app/pages/product/products_search_page.dart';
import 'package:my_pos_app/pages/supplier/supplier_page.dart'; // Import your Product model

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    // You can initialize products or any other data here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Orders'),
              onTap: () => Navigator.pushNamed(context, '/order'),
            ),
            ListTile(
              title: Text('History'),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              title: Text('Analytics'),
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProductsPage(
                            showAdminColumns: true,
                          )),
                );
              },
              child: Text('Go to Products Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CustomerPage(
                            showAdminColumns: true,
                          )),
                );
              },
              child: Text('Go to Customers Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CategoryPage(
                            showAdminColumns: true,
                          )),
                );
              },
              child: Text('Go to Category Page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SupplierPage(
                            showAdminColumns: true,
                          )),
                );
              },
              child: Text('Go to Supplier Page'),
            ),
          ],
        ),
      ),
    );
  }
}
