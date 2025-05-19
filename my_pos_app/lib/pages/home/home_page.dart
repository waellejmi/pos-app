import 'package:flutter/material.dart';
import '../admin_dashboard/admin_dashboard_page.dart'; // Import your admin dashboard page
import '../order/order_page.dart'; // Import your history page
import '../product/products_search_page.dart'; // Import your products page
import '../order/orders_history_page.dart'; // Import your orders page
import '../analytics/analytics_page.dart'; // Import your analytics page
import '../profile/profile_page.dart'; // Import your profile page

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.5,
        ),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item.page),
              );
            },
            child: Card(
              elevation: 4.0,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 50),
                    SizedBox(height: 10),
                    Text(item.title, style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  final List<MenuItem> _menuItems = [
    MenuItem('Admin Dashboard', Icons.dashboard, AdminDashboardPage()),
    MenuItem('Orders', Icons.shopping_cart, OrderPage()),
    MenuItem(
        'Products',
        Icons.list,
        ProductsPage(
          showAdminColumns: true,
        )),
    MenuItem('History', Icons.history, OrderHistoryPage()),
    MenuItem('Analytics', Icons.analytics, AnalyticsPage()),
    MenuItem('Profile', Icons.person, ProfilePage()),
  ];
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  MenuItem(this.title, this.icon, this.page);
}
