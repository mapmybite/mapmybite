import 'package:flutter/material.dart';
import 'order_data.dart';
import 'owner_customer_data.dart';
import 'truck_page.dart';
import 'orders_page.dart';
import 'truck_profile_page.dart';
import 'owner_portal_page.dart';
import 'vendor_data.dart';

class AdminPage extends StatefulWidget {
  final List<Map<String, dynamic>> vendors;
  final bool isDarkMode;
  final String adminRole;

  const AdminPage({
    super.key,
    required this.vendors,
    required this.isDarkMode,
    required this.adminRole,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _vendorFilter = 'All';
  String _orderFilter = 'All';
  String _customerFilter = 'All';

  Color get _bg => widget.isDarkMode ? Colors.black : Colors.grey.shade100;
  Color get _card => widget.isDarkMode ? Colors.grey.shade900 : Colors.white;
  Color get _text => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _subText =>
      widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

  List<Map<String, dynamic>> get _vendors => widget.vendors;
  List<Map<String, dynamic>> get _orders => OrderData.orders;
  List<Map<String, dynamic>> get _customers => OwnerCustomerData.customers;
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);
}
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _lower(dynamic value) => (value ?? '').toString().toLowerCase().trim();

  double _money(dynamic rawValue) {
    final raw = (rawValue ?? '0')
        .toString()
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(raw) ?? 0.0;
  }

  String _moneyText(double value) => '\$${value.toStringAsFixed(2)}';

  bool _isTruck(Map<String, dynamic> v) {
    final type = _lower(v['type']);
    return type == 'truck' || type == 'food_truck' || type.contains('truck');
  }

  bool _isKitchen(Map<String, dynamic> v) {
    final type = _lower(v['type']);
    return type == 'kitchen' ||
        type == 'home_kitchen' ||
        type.contains('kitchen') ||
        type.contains('home');
  }

  bool _isPendingOrder(Map<String, dynamic> o) {
    final status = _lower(o['status']);
    return status == 'pending';
  }

  bool _isCompletedOrder(Map<String, dynamic> o) {
    final status = _lower(o['status']);
    return status == 'completed';
  }

  List<Map<String, dynamic>> get _filteredVendors {
    var items = _vendors.where((v) {
      if (_vendorFilter == 'Food Trucks' && !_isTruck(v)) return false;
      if (_vendorFilter == 'Home Kitchens' && !_isKitchen(v)) return false;
      if (_vendorFilter == 'Pending Verify') {
        final hasVerificationData =
            (v['legalName'] ?? '').toString().trim().isNotEmpty ||
            (v['permitNumber'] ?? '').toString().trim().isNotEmpty ||
            (v['idFrontImage'] ?? '').toString().trim().isNotEmpty ||
            (v['addressProofImage'] ?? '').toString().trim().isNotEmpty;

        if (_lower(v['verificationStatus']) != 'pending' && !hasVerificationData) {
          return false;
        }
      }
      if (_vendorFilter == 'Approved' &&
          _lower(v['verificationStatus']) != 'approved') {
        return false;
      }
      if (_vendorFilter == 'Suspended' && v['isSuspended'] != true) {
        return false;
      }
      if (_vendorFilter == 'Featured' && v['isFeatured'] != true) {
        return false;
      }
      return true;
    }).toList();

    if (_searchText.trim().isEmpty) return items;

    final q = _searchText.toLowerCase().trim();

    return items.where((v) {
      final text = [
        v['title'],
        v['cuisine'],
        v['type'],
        v['plan'],
        v['phone'],
        v['address'],
        v['verificationStatus'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

      return text.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var items = _orders.where((o) {
      final status = _lower(o['status']);
      if (_orderFilter != 'All' && status != _orderFilter.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    if (_searchText.trim().isEmpty) return items;

    final q = _searchText.toLowerCase().trim();

    return items.where((o) {
      final text = [
        o['business'],
        o['customer'],
        o['phone'],
        o['status'],
        o['paymentType'],
        o['paymentStatus'],
        o['orderType'],
        o['items'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

      return text.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    var items = _customers.where((c) {
      final visits = ((c['visitCount'] ?? 0) as num).toInt();
      if (_customerFilter == 'Repeat' && visits <= 1) return false;
      if (_customerFilter == 'New' && visits > 1) return false;
      return true;
    }).toList();

    if (_searchText.trim().isEmpty) return items;

    final q = _searchText.toLowerCase().trim();

    return items.where((c) {
      final text = [
        c['business'],
        c['name'],
        c['phone'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

      return text.contains(q);
    }).toList();
  }

  int _planCount(String plan) {
    return _vendors.where((v) => _lower(v['plan']) == plan).length;
  }

  double _planMonthlyEstimate() {
    return (_planCount('pro') * 9.99) +
        (_planCount('premium') * 15.99) +
        (_planCount('platinum') * 29.99);
  }

  double _orderRevenue(List<Map<String, dynamic>> orders) {
    return orders.fold<double>(0.0, (sum, order) {
      return sum + _money(order['total']);
    });
  }

  DateTime? _orderDate(Map<String, dynamic> order) {
    final createdAt = (order['createdAt'] ?? '').toString().trim();
    if (createdAt.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) return parsed;
    }

    final date = (order['date'] ?? '').toString().trim();
    final parts = date.split('/');
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  bool _isTodayOrder(Map<String, dynamic> order) {
    final parsed = _orderDate(order);
    if (parsed == null) return false;

    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  bool _isThisWeekOrder(Map<String, dynamic> order) {
    final parsed = _orderDate(order);
    if (parsed == null) return false;

    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return parsed.isAfter(weekStart.subtract(const Duration(seconds: 1)));
  }

  bool _isThisMonthOrder(Map<String, dynamic> order) {
    final parsed = _orderDate(order);
    if (parsed == null) return false;

    final now = DateTime.now();
    return parsed.year == now.year && parsed.month == now.month;
  }

  int _vendorOrderCount(String businessName) {
    return _orders.where((o) {
      return _lower(o['business']) == businessName.trim().toLowerCase();
    }).length;
  }

  double _vendorRevenue(String businessName) {
    final vendorOrders = _orders.where((o) {
      return _lower(o['business']) == businessName.trim().toLowerCase();
    }).toList();

    return _orderRevenue(vendorOrders);
  }

  List<Map<String, dynamic>> _vendorOrders(String businessName) {
    return _orders.where((order) {
      return _lower(order['business']) ==
          businessName.trim().toLowerCase();
    }).toList().reversed.toList();
  }

  List<Map<String, dynamic>> _customerOrders(
    Map<String, dynamic> customer,
  ) {
    final phone = (customer['phone'] ?? '').toString().trim();

    final name =
        (customer['name'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    return _orders.where((order) {
      final orderPhone =
          (order['phone'] ?? '').toString().trim();

      final orderCustomer =
          (order['customer'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (phone.isNotEmpty && orderPhone == phone) {
        return true;
      }

      if (name.isNotEmpty && orderCustomer == name) {
        return true;
      }

      return false;
    }).toList().reversed.toList();
  }

  List<Map<String, dynamic>> _topVendors() {
    final copied = [..._vendors];

    copied.sort((a, b) {
      final aTitle = (a['title'] ?? '').toString();
      final bTitle = (b['title'] ?? '').toString();
      return _vendorRevenue(bTitle).compareTo(_vendorRevenue(aTitle));
    });

    return copied.take(5).toList();
  }

  Map<String, int> _activeAreaStats() {
    final Map<String, int> stats = {
      'Stockton': 0,
      'Manteca': 0,
      'Lathrop': 0,
      'French Camp': 0,
      'Other Areas': 0,
    };

    for (final vendor in _vendors) {
      final combined =
          '${vendor['address'] ?? ''} ${vendor['title'] ?? ''}'.toLowerCase();

      if (combined.contains('stockton')) {
        stats['Stockton'] = stats['Stockton']! + 1;
      } else if (combined.contains('manteca')) {
        stats['Manteca'] = stats['Manteca']! + 1;
      } else if (combined.contains('lathrop')) {
        stats['Lathrop'] = stats['Lathrop']! + 1;
      } else if (combined.contains('french camp')) {
        stats['French Camp'] = stats['French Camp']! + 1;
      } else {
        stats['Other Areas'] = stats['Other Areas']! + 1;
      }
    }

    return stats;
  }

  int _foodTruckCount() => _vendors.where(_isTruck).length;

  int _homeKitchenCount() => _vendors.where(_isKitchen).length;

  int _pendingVerificationCount() {
    return _vendors.where((v) {
      final status = _lower(v['verificationStatus']);

      final hasVerificationData =
          (v['legalName'] ?? '').toString().trim().isNotEmpty ||
          (v['permitNumber'] ?? '').toString().trim().isNotEmpty ||
          (v['idFrontImage'] ?? '').toString().trim().isNotEmpty ||
          (v['addressProofImage'] ?? '').toString().trim().isNotEmpty;

      return status == 'pending';
    }).length;
  }

  int _suspendedVendorCount() {
    return _vendors.where((v) => v['isSuspended'] == true).length;
  }

  int _featuredVendorCount() {
    return _vendors.where((v) => v['isFeatured'] == true).length;
  }

  int _repeatCustomerCount() {
    return _customers.where((c) {
      final visits = ((c['visitCount'] ?? 0) as num).toInt();
      return visits > 1;
    }).length;
  }

  List<Map<String, dynamic>> _pendingVerificationVendors() {
    return _vendors.where((v) {
      final status = _lower(v['verificationStatus']);

      final hasVerificationData =
          (v['legalName'] ?? '').toString().trim().isNotEmpty ||
          (v['permitNumber'] ?? '').toString().trim().isNotEmpty ||
          (v['idFrontImage'] ?? '').toString().trim().isNotEmpty ||
          (v['addressProofImage'] ?? '').toString().trim().isNotEmpty;

      return status == 'pending';
    }).toList();
  }

  void _showAdminActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _approveVendor(Map<String, dynamic> vendor) async {
    final title = (vendor['title'] ?? 'Vendor').toString();

    setState(() {
      vendor['isVerified'] = true;
      vendor['verificationStatus'] = 'approved';
    });

    await VendorData.addOrUpdateVendor(vendor);

    _showAdminActionMessage('$title approved');
  }

  Future<void> _rejectVendor(Map<String, dynamic> vendor) async {
    final title = (vendor['title'] ?? 'Vendor').toString();

    setState(() {
      vendor['isVerified'] = false;
      vendor['verificationStatus'] = 'rejected';
    });

    await VendorData.addOrUpdateVendor(vendor);

    _showAdminActionMessage('$title rejected');
  }

  Future<void> _toggleSuspendVendor(Map<String, dynamic> vendor) async {
    final title = (vendor['title'] ?? 'Vendor').toString();
    final next = vendor['isSuspended'] != true;

    setState(() {
      vendor['isSuspended'] = next;
    });

    await VendorData.addOrUpdateVendor(vendor);

    _showAdminActionMessage(next ? '$title suspended' : '$title unsuspended');
  }

  Future<void> _toggleFeaturedVendor(Map<String, dynamic> vendor) async {
    final title = (vendor['title'] ?? 'Vendor').toString();
    final next = vendor['isFeatured'] != true;

    setState(() {
      vendor['isFeatured'] = next;
    });

    await VendorData.addOrUpdateVendor(vendor);

    _showAdminActionMessage(
      next ? '$title marked featured' : '$title removed from featured',
    );
  }

  Future<void> _changeVendorPlan(
    Map<String, dynamic> vendor,
    String plan,
  ) async {
    final title = (vendor['title'] ?? 'Vendor').toString();

    setState(() {
      vendor['plan'] = plan.toLowerCase();
    });

    await VendorData.addOrUpdateVendor(vendor);

    _showAdminActionMessage('$title plan changed to $plan');
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _orderRevenue(_orders);
    final todayOrders = _orders.where(_isTodayOrder).toList();
    final weekOrders = _orders.where(_isThisWeekOrder).toList();
    final monthOrders = _orders.where(_isThisMonthOrder).toList();

    return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MapMyBite Admin',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.adminRole == 'owner'
                    ? 'Owner Access'
                    : 'Team Access',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Vendors'),
              Tab(text: 'Orders'),
              Tab(text: 'Customers'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBox(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(
                    totalRevenue: totalRevenue,
                    todayRevenue: _orderRevenue(todayOrders),
                    weekRevenue: _orderRevenue(weekOrders),
                    monthRevenue: _orderRevenue(monthOrders),
                    todayOrderCount: todayOrders.length,
                    monthlySubscriptionEstimate: _planMonthlyEstimate(),
                  ),
                  _buildVendorsTab(),
                  _buildOrdersTab(),
                  _buildCustomersTab(),
                  _buildActivityTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildSearchBox() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _text),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: _subText),
                  onPressed: () {
                    setState(() {
                      _searchText = '';
                      _searchController.clear();
                    });
                  },
                ),
          hintText: 'Search vendors, orders, customers...',
          hintStyle: TextStyle(color: _subText),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: widget.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: widget.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value;
            _vendorFilter = 'All';
            _orderFilter = 'All';
            _customerFilter = 'All';
          });

          final q = value.trim().toLowerCase();

          if (q.isEmpty) return;

          if (_tabController.index != 0) return;

          final hasVendorMatch = _filteredVendors.isNotEmpty;
          final hasOrderMatch = _filteredOrders.isNotEmpty;
          final hasCustomerMatch = _filteredCustomers.isNotEmpty;

          if (hasOrderMatch && !hasVendorMatch) {
            _tabController.animateTo(2);
          } else if (hasCustomerMatch && !hasVendorMatch && !hasOrderMatch) {
            _tabController.animateTo(3);
          } else if (hasVendorMatch) {
            _tabController.animateTo(1);
          }
        },
      ),
    );
  }

  Widget _buildOverviewTab({
    required double totalRevenue,
    required double todayRevenue,
    required double weekRevenue,
    required double monthRevenue,
    required int todayOrderCount,
    required double monthlySubscriptionEstimate,
  }) {
    final activeAreas = _activeAreaStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dashboard Overview', 'Tap any card to see details'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TruckPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Map View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Orders'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.30,
            children: [
              _statCard(
                Icons.store,
                'Total Vendors',
                _vendors.length.toString(),
                Colors.orange,
                onTap: () => _showSimpleDialog(
                  'Total Vendors',
                  'All businesses currently loaded in the app: ${_vendors.length}',
                ),
              ),
              _statCard(
                Icons.local_shipping,
                'Food Trucks',
                _foodTruckCount().toString(),
                Colors.red,
                onTap: () => _jumpVendorFilter('Food Trucks'),
              ),
              _statCard(
                Icons.home_work,
                'Home Kitchens',
                _homeKitchenCount().toString(),
                Colors.purple,
                onTap: () => _jumpVendorFilter('Home Kitchens'),
              ),
              _statCard(
                Icons.receipt_long,
                'Orders',
                _orders.length.toString(),
                Colors.blue,
                onTap: () => _showSimpleDialog(
                  'Orders',
                  'Total orders in current app data: ${_orders.length}',
                ),
              ),
              _statCard(
                Icons.attach_money,
                'Total Sales',
                _moneyText(totalRevenue),
                Colors.green,
                onTap: () => _showSimpleDialog(
                  'Total Sales',
                  'This is total order value from local order data. Later Firebase can separate MapMyBite fees vs vendor sales.',
                ),
              ),
              _statCard(
                Icons.today,
                'Today Sales',
                _moneyText(todayRevenue),
                Colors.teal,
                onTap: () => _showSimpleDialog(
                  'Today Sales',
                  '$todayOrderCount orders today • ${_moneyText(todayRevenue)} sales',
                ),
              ),
              _statCard(
                Icons.date_range,
                'Week Sales',
                _moneyText(weekRevenue),
                Colors.indigo,
                onTap: () => _showSimpleDialog(
                  'This Week',
                  '${_orders.where(_isThisWeekOrder).length} orders this week • ${_moneyText(weekRevenue)} sales',
                ),
              ),
              _statCard(
                Icons.calendar_month,
                'Month Sales',
                _moneyText(monthRevenue),
                Colors.deepPurple,
                onTap: () => _showSimpleDialog(
                  'This Month',
                  '${_orders.where(_isThisMonthOrder).length} orders this month • ${_moneyText(monthRevenue)} sales',
                ),
              ),
              _statCard(
                Icons.verified_user,
                'Pending Verify',
                _pendingVerificationCount().toString(),
                Colors.deepOrange,
                onTap: () => _jumpVendorFilter('Pending Verify'),
              ),
              _statCard(
                Icons.block,
                'Suspended',
                _suspendedVendorCount().toString(),
                Colors.redAccent,
                onTap: () => _jumpVendorFilter('Suspended'),
              ),
              _statCard(
                Icons.star,
                'Featured',
                _featuredVendorCount().toString(),
                Colors.amber,
                onTap: () => _jumpVendorFilter('Featured'),
              ),
              _statCard(
                Icons.people,
                'Customers',
                _customers.length.toString(),
                Colors.cyan,
                onTap: () => _showSimpleDialog(
                  'Customers',
                  '${_customers.length} customers saved from owner POS/order history.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _sectionTitle('Subscription Plans', 'Estimated monthly subscription income'),

          _planRow('Free', _planCount('free'), Colors.grey, '\$0.00/mo'),
          _planRow('Pro', _planCount('pro'), Colors.blue, '\$9.99/mo each'),
          _planRow('Premium', _planCount('premium'), Colors.purple, '\$15.99/mo each'),
          _planRow('Platinum', _planCount('platinum'), Colors.orange, '\$29.99/mo estimate'),

          _infoBanner(
            icon: Icons.payments,
            title: 'Estimated Subscription Revenue',
            message:
                '${_moneyText(monthlySubscriptionEstimate)} per month based on current plan counts.',
            color: Colors.green,
          ),

          const SizedBox(height: 22),

          _sectionTitle('Top Vendors', 'Tap vendor to manage'),

          if (_topVendors().isEmpty)
            _emptyText('No vendors yet.')
          else
            ..._topVendors().map(_topVendorTile),

          const SizedBox(height: 22),

          _sectionTitle('Active Areas', 'Vendor count by launch area'),

          ...activeAreas.entries.map((entry) => _areaRow(entry.key, entry.value)),

          const SizedBox(height: 22),

          _sectionTitle('Verification Requests', 'Approve or reject vendors'),

          if (_pendingVerificationVendors().isEmpty)
            _emptyText('No pending verification requests.')
          else
            ..._pendingVerificationVendors().map(_verificationTile),

          const SizedBox(height: 22),

          _infoBanner(
            icon: Icons.admin_panel_settings,
            title: 'Admin Note',
            message:
                'These actions are local placeholders right now. Later, Firebase will save approvals, suspensions, plans, reports, and admin logs permanently.',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  void _jumpVendorFilter(String filter) {
    setState(() => _vendorFilter = filter);
    _tabController.animateTo(1);
  }

  Widget _buildVendorsTab() {
    final items = _filteredVendors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Vendors', '${items.length} showing'),
          _filterWrap(
            selected: _vendorFilter,
            options: const [
              'All',
              'Food Trucks',
              'Home Kitchens',
              'Pending Verify',
              'Approved',
              'Suspended',
              'Featured',
            ],
            onSelected: (value) => setState(() => _vendorFilter = value),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _emptyText('No vendors match your search/filter.')
          else
            ...items.map(_vendorTile),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final items = _filteredOrders.reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Orders', '${items.length} showing'),
          _filterWrap(
            selected: _orderFilter,
            options: const [
              'All',
              'Pending',
              'Accepted',
              'Preparing',
              'Ready',
              'Completed',
              'Rejected',
            ],
            onSelected: (value) => setState(() => _orderFilter = value),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _emptyText('No orders match your search/filter.')
          else
            ...items.map(_orderTile),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    final items = _filteredCustomers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customers', '${items.length} showing'),
          _filterWrap(
            selected: _customerFilter,
            options: const ['All', 'Repeat', 'New'],
            onSelected: (value) => setState(() => _customerFilter = value),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _emptyText('No customers match your search/filter.')
          else
            ...items.map(_customerTile),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final recentOrders = _orders.reversed.take(10).toList();
    final recentCustomers = _customers.reversed.take(10).toList();
    final pendingOrders = _orders.where(_isPendingOrder).length;
    final completedOrders = _orders.where(_isCompletedOrder).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Real-Time Activity Feed', 'Latest app activity'),

          _miniSummaryRow(
            leftTitle: 'Pending Orders',
            leftValue: pendingOrders.toString(),
            leftIcon: Icons.pending_actions,
            leftColor: Colors.orange,
            rightTitle: 'Completed',
            rightValue: completedOrders.toString(),
            rightIcon: Icons.check_circle,
            rightColor: Colors.green,
          ),

          const SizedBox(height: 18),

          _sectionTitle('Moderation Center', 'Placeholders for Firebase/admin backend'),

          _adminToolTile(
            icon: Icons.report,
            color: Colors.red,
            title: 'Reported Vendors',
            subtitle: 'No reports yet. Later this will show unsafe or reported businesses.',
            onTap: () => _showSimpleDialog(
              'Reported Vendors',
              'No reported vendors in local demo data yet.',
            ),
          ),
          _adminToolTile(
            icon: Icons.person_off,
            color: Colors.deepOrange,
            title: 'Blocked Users',
            subtitle: 'Later admin can block customers or owners from Firebase.',
            onTap: () => _showSimpleDialog(
              'Blocked Users',
              'Block/unblock will be connected after login/backend.',
            ),
          ),
          _adminToolTile(
            icon: Icons.campaign,
            color: Colors.blue,
            title: 'Admin Announcements',
            subtitle: 'Future: send notice to vendors or customers.',
            onTap: () => _showSimpleDialog(
              'Admin Announcements',
              'Later you can send app notices like maintenance, offers, or safety alerts.',
            ),
          ),

          const SizedBox(height: 18),

          if (recentOrders.isNotEmpty) ...[
            Text(
              'Latest Orders',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...recentOrders.map((order) {
              return _activityTile(
                icon: Icons.receipt_long,
                color: Colors.orange,
                title: '${order['customer'] ?? 'Customer'} placed an order',
                subtitle:
                    '${order['business'] ?? 'Business'} • \$${order['total'] ?? '0.00'} • ${order['status'] ?? ''}',
                onTap: () => _showOrderDetails(order),
              );
            }),
          ],

          const SizedBox(height: 18),

          if (recentCustomers.isNotEmpty) ...[
            Text(
              'Latest Customers',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...recentCustomers.map((customer) {
              return _activityTile(
                icon: Icons.person,
                color: Colors.blue,
                title: '${customer['name'] ?? 'Customer'} updated',
                subtitle:
                    '${customer['business'] ?? 'Business'} • visits: ${customer['visitCount'] ?? 0} • rewards: ${customer['rewardPunches'] ?? 0}/5',
                onTap: () => _showCustomerDetails(customer),
              );
            }),
          ],

          if (recentOrders.isEmpty && recentCustomers.isEmpty)
            _emptyText('No activity yet.'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _text,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: _subText)),
        ],
      ),
    );
  }

  Widget _filterWrap({
    required String selected,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: Colors.orange.withValues(alpha: 0.22),
          backgroundColor: _card,
          labelStyle: TextStyle(
            color: isSelected ? Colors.orange : _text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? Colors.orange : Colors.grey.withValues(alpha: 0.35),
          ),
          onSelected: (_) => onSelected(option),
        );
      }).toList(),
    );
  }

  Widget _statCard(
    IconData icon,
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: widget.isDarkMode ? Border.all(color: Colors.grey.shade800) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text.withValues(alpha: 0.75),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap details',
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planRow(String title, int count, Color color, String subtitle) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showSimpleDialog(
        '$title Plan',
        '$count vendors are currently on $title plan.\n\n$subtitle',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: widget.isDarkMode ? Border.all(color: Colors.grey.shade800) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(Icons.workspace_premium, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: _subText, fontSize: 12)),
                ],
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();
    final type = (vendor['type'] ?? '').toString();
    final plan = (vendor['plan'] ?? 'free').toString();
    final isVerified = vendor['isVerified'] == true;
    final hasVerificationData =
        (vendor['legalName'] ?? '').toString().trim().isNotEmpty ||
        (vendor['permitNumber'] ?? '').toString().trim().isNotEmpty ||
        (vendor['idFrontImage'] ?? '').toString().trim().isNotEmpty ||
        (vendor['addressProofImage'] ?? '').toString().trim().isNotEmpty;

    final status = hasVerificationData
        ? 'pending'
        : (vendor['verificationStatus'] ?? 'not_started').toString();
    final isSuspended = vendor['isSuspended'] == true;
    final isFeatured = vendor['isFeatured'] == true;
    final color = _isTruck(vendor) ? Colors.orange : Colors.purple;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showVendorDetails(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(
              _isTruck(vendor) ? Icons.local_shipping : Icons.home_work,
              color: color,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: _text, fontWeight: FontWeight.bold),
                ),
              ),
              if (isFeatured) const Icon(Icons.star, color: Colors.amber, size: 18),
              if (isVerified) const Icon(Icons.verified, color: Colors.blue, size: 18),
              if (isSuspended) const Icon(Icons.block, color: Colors.red, size: 18),
            ],
          ),
          subtitle: Text(
            '${vendor['cuisine'] ?? ''}\n'
            'Type: $type • Plan: $plan • Status: $status\n'
            'Orders: ${_vendorOrderCount(title)} • Revenue: ${_moneyText(_vendorRevenue(title))}',
            style: TextStyle(color: _subText),
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _text),
            onSelected: (value) {
              if (value == 'approve') _approveVendor(vendor);
              if (value == 'reject') _rejectVendor(vendor);
              if (value == 'suspend') _toggleSuspendVendor(vendor);
              if (value == 'featured') _toggleFeaturedVendor(vendor);
              if (value.startsWith('plan_')) {
                _changeVendorPlan(vendor, value.replaceFirst('plan_', ''));
              }
              if (value == 'details') _showVendorDetails(vendor);
              if (value == 'delete') {
                _showAdminActionMessage(
                  'Delete placeholder: later connect to Firebase delete.',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'details', child: Text('View Details')),
              const PopupMenuItem(value: 'approve', child: Text('Approve Verification')),
              const PopupMenuItem(value: 'reject', child: Text('Reject Verification')),
              PopupMenuItem(
                value: 'suspend',
                child: Text(isSuspended ? 'Unsuspend Vendor' : 'Suspend Vendor'),
              ),
              PopupMenuItem(
                value: 'featured',
                child: Text(isFeatured ? 'Remove Featured' : 'Mark Featured'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'plan_free', child: Text('Set Plan: Free')),
              const PopupMenuItem(value: 'plan_pro', child: Text('Set Plan: Pro')),
              const PopupMenuItem(value: 'plan_premium', child: Text('Set Plan: Premium')),
              const PopupMenuItem(value: 'plan_platinum', child: Text('Set Plan: Platinum')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Text('Delete Placeholder')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verificationTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showVendorDetails(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.deepOrange,
            child: Icon(Icons.verified_user, color: Colors.white),
          ),
          title: Text(
            title,
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${vendor['cuisine'] ?? ''} • ${vendor['phone'] ?? ''}',
            style: TextStyle(color: _subText),
          ),
          trailing: Wrap(
            spacing: 6,
            children: [
              IconButton(
                tooltip: 'Approve',
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _approveVendor(vendor),
              ),
              IconButton(
                tooltip: 'Reject',
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _rejectVendor(vendor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString();
    final color = _orderStatusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(Icons.receipt_long, color: color),
          ),
          title: Text(
            order['business']?.toString() ?? 'Unknown Business',
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${order['customer'] ?? 'Customer'} • ${order['phone'] ?? ''}\n'
            '\$${order['total'] ?? '0.00'} • ${order['status'] ?? ''} • ${order['paymentStatus'] ?? ''}',
            style: TextStyle(color: _subText),
          ),
          trailing: const Icon(Icons.chevron_right),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _customerTile(Map<String, dynamic> customer) {
    final visits = ((customer['visitCount'] ?? 0) as num).toInt();
    final repeat = visits > 1;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showCustomerDetails(customer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: repeat ? Colors.green : Colors.blue,
            child: Icon(repeat ? Icons.repeat : Icons.person, color: Colors.white),
          ),
          title: Text(
            customer['name']?.toString() ?? 'Customer',
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${customer['business'] ?? 'Business'} • ${customer['phone'] ?? ''}\n'
            'Visits: ${customer['visitCount'] ?? 0} • Rewards: ${customer['rewardPunches'] ?? 0}/5 • Spent: \$${customer['totalSpent'] ?? 0}',
            style: TextStyle(color: _subText),
          ),
          trailing: const Icon(Icons.chevron_right),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _topVendorTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();
    final orders = _vendorOrderCount(title);
    final revenue = _vendorRevenue(title);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showVendorDetails(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.trending_up, color: Colors.white),
          ),
          title: Text(
            title,
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$orders orders • ${_moneyText(revenue)} revenue',
            style: TextStyle(color: _subText),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _areaRow(String area, int count) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showSimpleDialog(area, '$count vendors found in this launch area.'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration(),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                area,
                style: TextStyle(color: _text, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _boxDecoration(),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle, style: TextStyle(color: _subText)),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _adminToolTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _activityTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _miniSummaryRow({
    required String leftTitle,
    required String leftValue,
    required IconData leftIcon,
    required Color leftColor,
    required String rightTitle,
    required String rightValue,
    required IconData rightIcon,
    required Color rightColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _smallSummaryCard(leftTitle, leftValue, leftIcon, leftColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallSummaryCard(rightTitle, rightValue, rightIcon, rightColor),
        ),
      ],
    );
  }

  Widget _smallSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: _subText, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Color _orderStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed')) return Colors.green;
    if (s.contains('ready')) return Colors.teal;
    if (s.contains('preparing')) return Colors.orange;
    if (s.contains('accepted')) return Colors.blue;
    if (s.contains('rejected')) return Colors.red;
    return Colors.deepOrange;
  }

  Widget _infoBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showSimpleDialog(title, message),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: _text, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: _subText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: TextStyle(color: _subText)),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      border: widget.isDarkMode ? Border.all(color: Colors.grey.shade800) : null,
      boxShadow: [
        if (!widget.isDarkMode)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
      ],
    );
  }

  void _showSimpleDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text(title, style: TextStyle(color: _text)),
        content: Text(message, style: TextStyle(color: _subText, height: 1.35)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  Future<void> _editVendorProfile(Map<String, dynamic> vendor) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerPortalPage(
          existingData: vendor,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result == null) return;

    await VendorData.addOrUpdateVendor(result);

    if (!mounted) return;

    setState(() {
      vendor.addAll(result);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor profile updated'),
      ),
    );
  }
  void _showVendorCustomersRewards(String businessName) {
    setState(() {
      _searchText = businessName;
      _searchController.text = businessName;
    });

    _tabController.animateTo(3);
  }

  void _showVendorDetails(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final plan = (vendor['plan'] ?? 'free').toString();
            final isSuspended = vendor['isSuspended'] == true;
            final isFeatured = vendor['isFeatured'] == true;
            final isVerified = vendor['isVerified'] == true;
            final status = (vendor['verificationStatus'] ?? 'not_started').toString();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),
                    Text(
                      title,
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${vendor['cuisine'] ?? ''} • ${vendor['type'] ?? ''}',
                      style: TextStyle(color: _subText),
                    ),
                    const SizedBox(height: 14),

                    _detailLine('Phone', vendor['phone']),
                    _detailLine('Address', vendor['address']),
                    _detailLine('Plan', plan),
                    _detailLine(
                      'Verification Alert',
                      (
                        (vendor['legalName'] ?? '').toString().trim().isNotEmpty ||
                        (vendor['permitNumber'] ?? '').toString().trim().isNotEmpty ||
                        (vendor['idFrontImage'] ?? '').toString().trim().isNotEmpty ||
                        (vendor['addressProofImage'] ?? '').toString().trim().isNotEmpty
                      )
                          ? 'New verification documents submitted'
                          : 'No documents submitted',
                    ),
                    _detailLine('Verified', isVerified ? 'Yes' : 'No'),
                    _detailLine('Suspended', isSuspended ? 'Yes' : 'No'),
                    _detailLine('Featured', isFeatured ? 'Yes' : 'No'),
                    _detailLine('Orders', _vendorOrderCount(title)),
                    _detailLine('Revenue', _moneyText(_vendorRevenue(title))),

                    const SizedBox(height: 12),

                    Text(
                      'Recent Vendor Orders',
                      style: TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_vendorOrders(title).isEmpty)
                      _emptyText('No orders for this vendor yet.')
                    else
                      ..._vendorOrders(title).take(5).map((order) {
                        return _orderTile(order);
                      }),

                      if (_vendorOrders(title).isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View All Vendor Orders'),
                            onPressed: () {
                              Navigator.pop(context);

                              setState(() {
                                _searchText = title;
                                _searchController.text = title;
                              });

                              _tabController.animateTo(2);
                            },
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showVendorCustomersRewards(title);
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('View Customers & Rewards'),
                          ),
                        ),

                        const SizedBox(height: 10),

                    const SizedBox(height: 12),

                    _detailLine('Legal Name', vendor['legalName']),
                    _detailLine('Permit Number', vendor['permitNumber']),
                    _detailLine('Verification Notes', vendor['verificationNotes']),
                    _detailLine('ID Proof Image', vendor['idFrontImage']),
                    _detailLine('Address Proof Image', vendor['addressProofImage']),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editVendorProfile(vendor);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Owner Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TruckProfilePage(
                                truck: vendor,
                                isOwner: false,
                                initialIsFavorite: false,
                                isDarkMode: widget.isDarkMode,
                                isGuestMode: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.storefront),
                        label: const Text('Open Vendor Profile'),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Admin Actions',
                      style: TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _actionChip(
                          label: 'Approve',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () async {
                            await _approveVendor(vendor);
                            sheetSetState(() {});
                          },
                        ),
                        _actionChip(
                          label: 'Reject',
                          icon: Icons.cancel,
                          color: Colors.red,
                          onTap: () async {
                            await _rejectVendor(vendor);
                            sheetSetState(() {});
                          },
                        ),
                        _actionChip(
                          label: isSuspended ? 'Unsuspend' : 'Suspend',
                          icon: Icons.block,
                          color: Colors.deepOrange,
                          onTap: () async {
                            await _toggleSuspendVendor(vendor);
                            sheetSetState(() {});
                          },
                        ),
                        _actionChip(
                          label: isFeatured ? 'Unfeature' : 'Feature',
                          icon: Icons.star,
                          color: Colors.amber,
                          onTap: () async {
                            await _toggleFeaturedVendor(vendor);
                            sheetSetState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Change Plan',
                      style: TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Free', 'Pro', 'Premium', 'Platinum'].map((p) {
                        final selected = plan.toLowerCase() == p.toLowerCase();
                        return ChoiceChip(
                          label: Text(p),
                          selected: selected,
                          selectedColor: Colors.orange.withValues(alpha: 0.22),
                          onSelected: (_) async {
                            await _changeVendorPlan(vendor, p);
                            sheetSetState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                Text(
                  'Order Details',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _detailLine('Business', order['business']),
                _detailLine('Customer', order['customer']),
                _detailLine('Phone', order['phone']),
                _detailLine('Status', order['status']),
                _detailLine('Payment Type', order['paymentType']),
                _detailLine('Payment Status', order['paymentStatus']),
                _detailLine('Order Type', order['orderType']),
                _detailLine('Date', order['date']),
                _detailLine('Time', order['time']),
                _detailLine('Total', '\$${order['total'] ?? '0.00'}'),
                _detailLine('Items', order['items']),
                _detailLine('Notes', order['notes']),
                const SizedBox(height: 16),
                _infoBanner(
                  icon: Icons.info,
                  title: 'Admin Note',
                  message:
                      'Later we can add refund flag, dispute flag, driver issue, or vendor complaint tools here.',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                Text(
                  customer['name']?.toString() ?? 'Customer',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _detailLine('Business', customer['business']),
                _detailLine('Phone', customer['phone']),
                _detailLine('Visits', customer['visitCount']),
                _detailLine('Reward Punches', '${customer['rewardPunches'] ?? 0}/5'),
                _detailLine('Total Spent', '\$${customer['totalSpent'] ?? 0}'),
                _detailLine('Last Visit', customer['lastVisit']),

                const SizedBox(height: 16),

                Text(
                  'Customer Order History',
                  style: TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (_customerOrders(customer).isEmpty)
                  _emptyText('No orders found for this customer.')
                else
                  ..._customerOrders(customer).take(5).map((order) {
                    return _orderTile(order);
                  }),
                  if (_customerOrders(customer).isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View All Customer Orders'),
                        onPressed: () {
                          Navigator.pop(context);

                          final phone = (customer['phone'] ?? '').toString().trim();
                          final name = (customer['name'] ?? '').toString().trim();

                          setState(() {
                            _searchText = phone.isNotEmpty ? phone : name;
                            _searchController.text = _searchText;
                          });

                          _tabController.animateTo(2);
                        },
                      ),
                    ),

                const SizedBox(height: 16),

                _infoBanner(
                  icon: Icons.security,
                  title: 'Customer Moderation',
                  message:
                      'Later admin can view reports, block abusive users, or remove unsafe accounts from Firebase.',
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _detailLine(String label, dynamic value) {
    final textValue = (value == null || value.toString().trim().isEmpty)
        ? 'Not added'
        : value.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: _subText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              textValue,
              style: TextStyle(color: _text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: _text, fontWeight: FontWeight.w600),
    );
  }
}