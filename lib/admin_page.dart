import 'package:flutter/material.dart';
import 'order_data.dart';
import 'owner_customer_data.dart';

class AdminPage extends StatefulWidget {
  final List<Map<String, dynamic>> vendors;
  final bool isDarkMode;

  const AdminPage({
    super.key,
    required this.vendors,
    required this.isDarkMode,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Color get _bg => widget.isDarkMode ? Colors.black : Colors.grey.shade100;
  Color get _card => widget.isDarkMode ? Colors.grey.shade900 : Colors.white;
  Color get _text => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _subText =>
      widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

  List<Map<String, dynamic>> get _vendors => widget.vendors;

  List<Map<String, dynamic>> get _orders => OrderData.orders;

  List<Map<String, dynamic>> get _customers => OwnerCustomerData.customers;

  List<Map<String, dynamic>> get _filteredVendors {
    if (_searchText.trim().isEmpty) return _vendors;

    final q = _searchText.toLowerCase().trim();

    return _vendors.where((v) {
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
    if (_searchText.trim().isEmpty) return _orders;

    final q = _searchText.toLowerCase().trim();

    return _orders.where((o) {
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
    if (_searchText.trim().isEmpty) return _customers;

    final q = _searchText.toLowerCase().trim();

    return _customers.where((c) {
      final text = [
        c['business'],
        c['name'],
        c['phone'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

      return text.contains(q);
    }).toList();
  }

  int _planCount(String plan) {
    return _vendors.where((v) {
      return (v['plan'] ?? 'free').toString().toLowerCase() == plan;
    }).length;
  }

  double _planMonthlyEstimate() {
    final pro = _planCount('pro') * 9.99;
    final premium = _planCount('premium') * 15.99;

    // You can change Platinum price later when final.
    final platinum = _planCount('platinum') * 29.99;

    return pro + premium + platinum;
  }

  double _orderRevenue(List<Map<String, dynamic>> orders) {
    return orders.fold<double>(0.0, (sum, order) {
      final raw = (order['total'] ?? '0').toString().replaceAll('\$', '');
      final value = double.tryParse(raw) ?? 0.0;
      return sum + value;
    });
  }

  bool _isTodayOrder(Map<String, dynamic> order) {
    final now = DateTime.now();
    final todayText = '${now.month}/${now.day}/${now.year}';

    final date = (order['date'] ?? '').toString().trim();

    if (date == todayText) return true;

    final createdAt = (order['createdAt'] ?? '').toString().trim();

    if (createdAt.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day;
      }
    }

    return false;
  }

  List<Map<String, dynamic>> _todayOrders() {
    return _orders.where(_isTodayOrder).toList();
  }

  int _vendorOrderCount(String businessName) {
    return _orders.where((o) {
      return (o['business'] ?? '').toString().trim().toLowerCase() ==
          businessName.trim().toLowerCase();
    }).length;
  }

  double _vendorRevenue(String businessName) {
    final vendorOrders = _orders.where((o) {
      return (o['business'] ?? '').toString().trim().toLowerCase() ==
          businessName.trim().toLowerCase();
    }).toList();

    return _orderRevenue(vendorOrders);
  }

  List<Map<String, dynamic>> _topVendors() {
    final copied = [..._vendors];

    copied.sort((a, b) {
      final aTitle = (a['title'] ?? '').toString();
      final bTitle = (b['title'] ?? '').toString();

      final aRevenue = _vendorRevenue(aTitle);
      final bRevenue = _vendorRevenue(bTitle);

      return bRevenue.compareTo(aRevenue);
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
      final address = (vendor['address'] ?? '').toString().toLowerCase();
      final title = (vendor['title'] ?? '').toString().toLowerCase();

      final combined = '$address $title';

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

  int _foodTruckCount() {
    return _vendors.where((v) {
      final type = (v['type'] ?? '').toString().toLowerCase();
      return type == 'food_truck' || type == 'truck';
    }).length;
  }

  int _homeKitchenCount() {
    return _vendors.where((v) {
      final type = (v['type'] ?? '').toString().toLowerCase();
      return type == 'kitchen' || type == 'home_kitchen';
    }).length;
  }

  int _pendingVerificationCount() {
    return _vendors.where((v) {
      final status = (v['verificationStatus'] ?? '').toString().toLowerCase();
      return status == 'pending';
    }).length;
  }

  int _repeatCustomerCount() {
    return _customers.where((c) {
      final visits = ((c['visitCount'] ?? 0) as num).toInt();
      return visits > 1;
    }).length;
  }

  List<Map<String, dynamic>> _pendingVerificationVendors() {
    return _vendors.where((v) {
      final status = (v['verificationStatus'] ?? '').toString().toLowerCase();
      return status == 'pending';
    }).toList();
  }

  void _showAdminActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _orderRevenue(_orders);
    final todayOrders = _todayOrders();
    final todayRevenue = _orderRevenue(todayOrders);
    final monthlySubscriptionEstimate = _planMonthlyEstimate();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'MapMyBite Admin',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
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
                children: [
                  _buildOverviewTab(
                    totalRevenue: totalRevenue,
                    todayRevenue: todayRevenue,
                    todayOrderCount: todayOrders.length,
                    monthlySubscriptionEstimate: monthlySubscriptionEstimate,
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
              color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
          });
        },
      ),
    );
  }

  Widget _buildOverviewTab({
    required double totalRevenue,
    required double todayRevenue,
    required int todayOrderCount,
    required double monthlySubscriptionEstimate,
  }) {
    final activeAreas = _activeAreaStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dashboard Overview', 'Live stats from current app data'),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.32,
            children: [
              _statCard(Icons.store, 'Total Vendors', _vendors.length.toString(), Colors.orange),
              _statCard(Icons.local_shipping, 'Food Trucks', _foodTruckCount().toString(), Colors.red),
              _statCard(Icons.home_work, 'Home Kitchens', _homeKitchenCount().toString(), Colors.purple),
              _statCard(Icons.receipt_long, 'Orders', _orders.length.toString(), Colors.blue),
              _statCard(Icons.attach_money, 'Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Colors.green),
              _statCard(Icons.today, 'Today Revenue', '\$${todayRevenue.toStringAsFixed(2)}', Colors.teal),
              _statCard(Icons.shopping_bag, 'Today Orders', todayOrderCount.toString(), Colors.indigo),
              _statCard(Icons.verified_user, 'Pending Verify', _pendingVerificationCount().toString(), Colors.deepOrange),
              _statCard(Icons.people, 'Customers', _customers.length.toString(), Colors.cyan),
              _statCard(Icons.repeat, 'Repeat Customers', _repeatCustomerCount().toString(), Colors.pink),
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
            message: '\$${monthlySubscriptionEstimate.toStringAsFixed(2)} per month based on current plan counts.',
            color: Colors.green,
          ),

          const SizedBox(height: 22),

          _sectionTitle('Top Vendors', 'Ranked by order revenue'),

          if (_topVendors().isEmpty)
            _emptyText('No vendors yet.')
          else
            ..._topVendors().map(_topVendorTile),

          const SizedBox(height: 22),

          _sectionTitle('Active Areas', 'Vendor count by launch area'),

          ...activeAreas.entries.map((entry) {
            return _areaRow(entry.key, entry.value);
          }),

          const SizedBox(height: 22),

          _sectionTitle('Verification Requests', 'Vendors waiting for approval'),

          if (_pendingVerificationVendors().isEmpty)
            _emptyText('No pending verification requests.')
          else
            ..._pendingVerificationVendors().map(_verificationTile),
        ],
      ),
    );
  }

  Widget _buildVendorsTab() {
    final items = _filteredVendors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Vendors', '${items.length} showing'),

          if (items.isEmpty)
            _emptyText('No vendors match your search.')
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

          if (items.isEmpty)
            _emptyText('No orders match your search.')
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

          if (items.isEmpty)
            _emptyText('No customers match your search.')
          else
            ...items.map(_customerTile),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final recentOrders = _orders.reversed.take(10).toList();
    final recentCustomers = _customers.reversed.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Real-Time Activity Feed', 'Latest orders and customer activity'),

          if (recentOrders.isEmpty && recentCustomers.isEmpty)
            _emptyText('No activity yet.'),

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
              );
            }),
          ],
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
          Text(
            subtitle,
            style: TextStyle(color: _subText),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
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
        border: widget.isDarkMode
            ? Border.all(color: Colors.grey.shade800)
            : null,
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
              fontSize: 21,
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
        ],
      ),
    );
  }

  Widget _planRow(String title, int count, Color color, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: widget.isDarkMode
            ? Border.all(color: Colors.grey.shade800)
            : null,
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
                Text(
                  subtitle,
                  style: TextStyle(color: _subText, fontSize: 12),
                ),
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
    );
  }

  Widget _vendorTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();
    final type = (vendor['type'] ?? '').toString();
    final plan = (vendor['plan'] ?? 'free').toString();
    final isVerified = vendor['isVerified'] == true;
    final status = (vendor['verificationStatus'] ?? 'not_started').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == 'truck'
              ? Colors.orange.withValues(alpha: 0.18)
              : Colors.purple.withValues(alpha: 0.18),
          child: Icon(
            type == 'truck' ? Icons.local_shipping : Icons.home_work,
            color: type == 'truck' ? Colors.orange : Colors.purple,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isVerified)
              const Icon(Icons.verified, color: Colors.blue, size: 18),
          ],
        ),
        subtitle: Text(
          '${vendor['cuisine'] ?? ''}\nPlan: $plan • Status: $status\nOrders: ${_vendorOrderCount(title)} • Revenue: \$${_vendorRevenue(title).toStringAsFixed(2)}',
          style: TextStyle(color: _subText),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: _text),
          onSelected: (value) {
            if (value == 'approve') {
              setState(() {
                vendor['isVerified'] = true;
                vendor['verificationStatus'] = 'approved';
              });
              _showAdminActionMessage('$title approved');
            } else if (value == 'reject') {
              setState(() {
                vendor['isVerified'] = false;
                vendor['verificationStatus'] = 'rejected';
              });
              _showAdminActionMessage('$title rejected');
            } else if (value == 'suspend') {
              setState(() {
                vendor['isSuspended'] = true;
              });
              _showAdminActionMessage('$title marked as suspended');
            } else if (value == 'delete') {
              _showAdminActionMessage(
                'Delete placeholder: later we will connect this to database delete.',
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'approve', child: Text('Approve Verification')),
            PopupMenuItem(value: 'reject', child: Text('Reject Verification')),
            PopupMenuItem(value: 'suspend', child: Text('Suspend Vendor')),
            PopupMenuItem(value: 'delete', child: Text('Delete Placeholder')),
          ],
        ),
      ),
    );
  }

  Widget _verificationTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepOrange,
          child: Icon(Icons.verified_user, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
          ),
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
              onPressed: () {
                setState(() {
                  vendor['isVerified'] = true;
                  vendor['verificationStatus'] = 'approved';
                });
                _showAdminActionMessage('$title approved');
              },
            ),
            IconButton(
              tooltip: 'Reject',
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                setState(() {
                  vendor['isVerified'] = false;
                  vendor['verificationStatus'] = 'rejected';
                });
                _showAdminActionMessage('$title rejected');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          order['business']?.toString() ?? 'Unknown Business',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${order['customer'] ?? 'Customer'} • ${order['phone'] ?? ''}\n'
              '\$${order['total'] ?? '0.00'} • ${order['status'] ?? ''} • ${order['paymentStatus'] ?? ''}',
          style: TextStyle(color: _subText),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _customerTile(Map<String, dynamic> customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          customer['name']?.toString() ?? 'Customer',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${customer['business'] ?? 'Business'} • ${customer['phone'] ?? ''}\n'
              'Visits: ${customer['visitCount'] ?? 0} • Rewards: ${customer['rewardPunches'] ?? 0}/5 • Spent: \$${customer['totalSpent'] ?? 0}',
          style: TextStyle(color: _subText),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _topVendorTile(Map<String, dynamic> vendor) {
    final title = (vendor['title'] ?? 'Unnamed Vendor').toString();
    final orders = _vendorOrderCount(title);
    final revenue = _vendorRevenue(title);

    return Container(
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
          '$orders orders • \$${revenue.toStringAsFixed(2)} revenue',
          style: TextStyle(color: _subText),
        ),
      ),
    );
  }

  Widget _areaRow(String area, int count) {
    return Container(
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
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.bold,
              ),
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
    );
  }

  Widget _activityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: _subText),
        ),
      ),
    );
  }

  Widget _infoBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
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
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: _subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: _subText),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      border: widget.isDarkMode
          ? Border.all(color: Colors.grey.shade800)
          : null,
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
}