import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_pos_app/models/order.dart';
import 'package:my_pos_app/pages/order/order_detail_page.dart';
import 'package:my_pos_app/services/api_service.dart';
import 'package:my_pos_app/services/utility_service.dart';
import 'package:my_pos_app/widgets/calendar_button.dart';
import 'package:my_pos_app/widgets/pagination_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final ApiService _apiService = ApiService();
  DateTime? _selectedDay;
  List<Order> _orders = [];
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  String _statusFilter = '';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Completed',
    'Processing',
    'Canceled'
  ];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchOrders(DateTime.now(), 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchOrders(DateTime date, int page) async {
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await _apiService.getOrders(
        token: token!,
        page: page,
        search: _searchQuery,
        status: _statusFilter.isEmpty || _statusFilter == 'All'
            ? ''
            : _statusFilter.toLowerCase(),
        date: formattedDate,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Order> orders = (data['orders']['data'] as List<dynamic>?)
                ?.map((item) => Order.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
        final Map<String, dynamic> meta = data['orders']['meta'] ?? {};

        setState(() {
          _orders = orders;
          _currentPage = meta['currentPage'] ?? 1;
          _lastPage = meta['lastPage'] ?? 1;
          _selectedDay = date;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print('$error');
      UiService.showSnackBar(
        context,
        'Failed to load orders: $error',
      );
    }
  }

  void _onDateSelected(List<DateTime?> dates) {
    if (dates.isNotEmpty && dates.first != null) {
      _fetchOrders(dates.first!, 1);
    } else {
      setState(() {
        _orders = [];
        _currentPage = 1;
        _lastPage = 1;
      });
    }
  }

  void _onPageChanged(int page) {
    if (_selectedDay != null) {
      _fetchOrders(_selectedDay!, page);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(Duration(seconds: 1), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1; // Reset to page 1 on new search
      });
      _fetchOrders(_selectedDay ?? DateTime.now(), _currentPage);
    });
  }

  void _onStatusChanged(String? newStatus) {
    setState(() {
      _statusFilter = newStatus ?? '';
      _currentPage = 1; // Reset to page 1 on status change
    });
    _fetchOrders(_selectedDay ?? DateTime.now(), _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar at the top with horizontal margin
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search Orders',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            SizedBox(height: 16.0),

            // Centered date picker and dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CalendarButton(
                  initialDates: _selectedDay != null ? [_selectedDay!] : [],
                  onDatesChanged: _onDateSelected,
                ),
                SizedBox(width: 16.0), // Space between buttons
                DropdownButton<String>(
                  value: _statusFilter.isEmpty ? 'All' : _statusFilter,
                  onChanged: _onStatusChanged,
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Orders table and pagination
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: _buildOrderDataTable(_orders),
              ),
            ),
            PaginationWidget(
              currentPage: _currentPage,
              lastPage: _lastPage,
              onPageChanged: _onPageChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDataTable(List<Order> orders) {
    final DateFormat timeFormat = DateFormat('h:mm a'); // Time format

    return DataTable(
      columns: <DataColumn>[
        DataColumn(
          label: Container(
            color: Colors.grey[300], // Grey background for column headers
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Order Number',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Container(
            color: Colors.grey[300], // Grey background for column headers
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Container(
            color: Colors.grey[300], // Grey background for column headers
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Created',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Container(
            color: Colors.grey[300], // Grey background for column headers
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'More',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
      rows: orders.map((order) {
        return DataRow(
          cells: [
            DataCell(Text(order.orderNumber)),
            DataCell(Text(order.status)),
            DataCell(Text(timeFormat.format(order.createdAt))), // Format time
            DataCell(
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(orderId: order.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
