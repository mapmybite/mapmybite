import 'package:flutter/material.dart';
import 'customer_order_history_page.dart';
import 'customer_favorites_page.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Guest Customer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _ProfileTile(
            icon: Icons.favorite_border,
            title: 'Favorites',
            subtitle: 'Saved food trucks and kitchens',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerFavoritesPage(),
                ),
              );
            },
          ),
          _ProfileTile(
            icon: Icons.receipt_long,
            title: 'Order History',
            subtitle: 'View your past orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerOrderHistoryPage(),
                ),
              );
            },
          ),
          _ProfileTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English, Spanish, Punjabi/Hindi later',
          ),
          _ProfileTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Use the moon toggle on the map for now',
          ),
          _ProfileTile(
            icon: Icons.help_outline,
            title: 'Help & Report Issue',
            subtitle: 'Contact support or report a problem',
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1F1F1F),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade400),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}