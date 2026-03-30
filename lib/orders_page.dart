import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_data.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  void _updateStatus(int index, String newStatus) {
    setState(() {
      OrderData.orders[index]['status'] = newStatus;
    });
  }

  Future<void> _copyText(String label, String value) async {
    if (value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App not installed or cannot open')),
      );
    }
  }

  Widget _paymentRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? openUrl,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // OPEN BUTTON (only if URL available)
          if (openUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openUrl(openUrl),
            ),

          TextButton(
            onPressed: () => _copyText(label, value),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentOptionsDialog(int index) async {
    final order = OrderData.orders[index];

    final String cashApp = (order['cashApp'] ?? '').toString().trim();
    final String zelle = (order['zelle'] ?? '').toString().trim();
    final String venmo = (order['venmo'] ?? '').toString().trim();

    final bool hasAnyPaymentMethod =
        cashApp.isNotEmpty || zelle.isNotEmpty || venmo.isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Payment Options'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask customer to pay using one of these:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),

                if (hasAnyPaymentMethod) ...[
                  _paymentRow(
                    label: 'Cash App',
                    value: cashApp,
                    icon: Icons.attach_money,
                    color: Colors.green,
                    openUrl: cashApp.isNotEmpty
                        ? 'https://cash.app/\$${cashApp.replaceAll('\$', '')}'
                        : null,
                  ),
                  _paymentRow(
                    label: 'Zelle',
                    value: zelle,
                    icon: Icons.account_balance,
                    color: Colors.purple,
                  ),
                  _paymentRow(
                    label: 'Venmo',
                    value: venmo,
                    icon: Icons.payments,
                    color: Colors.blue,
                    openUrl: venmo.isNotEmpty
                        ? 'https://venmo.com/${venmo.replaceAll('@', '')}'
                        : null,
                  ),
                ] else ...[
                  const Text('No payment methods added'),
                ],

                const SizedBox(height: 14),
                const Text(
                  'After payment, tap "Payment Received"',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateStatus(index, 'Payment Pending');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order accepted'),
                  ),
                );
              },
              child: const Text('Accept Order'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderData.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final status = order['status'] ?? 'Pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['business'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),
                  Text('Items: ${order['items']}'),
                  Text('Customer: ${order['customer']}'),
                  Text('Phone: ${order['phone']}'),
                  Text('Status: $status'),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: status == 'Pending'
                            ? () => _showPaymentOptionsDialog(index)
                            : null,
                        child: const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: status == 'Payment Pending'
                            ? () => _updateStatus(index, 'Paid')
                            : null,
                        child: const Text('Payment Received'),
                      ),
                      ElevatedButton(
                        onPressed: status == 'Paid'
                            ? () => _updateStatus(index, 'Ready')
                            : null,
                        child: const Text('Ready'),
                      ),
                      ElevatedButton(
                        onPressed: status == 'Ready'
                            ? () => _updateStatus(index, 'Completed')
                            : null,
                        child: const Text('Complete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}