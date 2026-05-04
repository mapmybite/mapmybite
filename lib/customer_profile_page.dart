import 'package:flutter/material.dart';
import 'customer_order_history_page.dart';
import 'customer_favorites_page.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choose Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _LanguageOption(title: 'English', subtitle: 'Available now'),
              _LanguageOption(title: 'Spanish', subtitle: 'Coming soon'),
              _LanguageOption(title: 'Punjabi / Hindi', subtitle: 'Coming soon'),
            ],
          ),
        );
      },
    );
  }

  void _showDarkModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Dark Mode',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Dark mode is already active on this profile. Use the moon toggle on the map screen to switch app theme.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpReportIssue(BuildContext context) {
    final TextEditingController issueController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Help & Report Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tell us what happened. Later this can send directly to your admin dashboard or email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: issueController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Example: vendor info wrong, order issue, app bug...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report saved for now. Admin dashboard/email connection later.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            subtitle: 'English now, Spanish and Punjabi/Hindi later',
            onTap: () => _showLanguagePicker(context),
          ),
          _ProfileTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Theme info and settings',
            onTap: () => _showDarkModeInfo(context),
          ),
          _ProfileTile(
            icon: Icons.help_outline,
            title: 'Help & Report Issue',
            subtitle: 'Contact support or report a problem',
            onTap: () => _showHelpReportIssue(context),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.translate, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade400),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title selected')),
        );
      },
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