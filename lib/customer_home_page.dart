import 'package:flutter/material.dart';

import 'truck_page.dart';
import 'customer_order_history_page.dart';
import 'customer_profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  int _mapRefreshKey = 0;

  List<Widget> get _pages => [
    TruckPage(key: ValueKey(_mapRefreshKey)),
    const _RewardsPlaceholderPage(),
    const CustomerOrderHistoryPage(),
    const CustomerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _mapRefreshKey++;
            }

            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RewardsPlaceholderPage extends StatelessWidget {
  const _RewardsPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Rewards coming soon'),
    );
  }
}

class _OrdersPlaceholderPage extends StatelessWidget {
  const _OrdersPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Orders coming soon'),
    );
  }
}

class _ProfilePlaceholderPage extends StatelessWidget {
  const _ProfilePlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile coming soon'),
    );
  }
}