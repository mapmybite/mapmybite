import 'package:flutter/material.dart';
import 'order_data.dart';

class CustomerOrderHistoryPage extends StatelessWidget {
  const CustomerOrderHistoryPage({super.key});

  List<Map<String, dynamic>> _getOrders() {
    return OrderData.getCustomerOrders();
  }

  dynamic _pickFirstValue(Map<String, dynamic> order, List<String> keys) {
    for (final key in keys) {
      final value = order[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      return value;
    }
    return null;
  }

  String _formatDate(Map<String, dynamic> order) {
    final String date = (order['date'] ?? '').toString().trim();
    final String time = (order['time'] ?? '').toString().trim();

    if (date.isNotEmpty || time.isNotEmpty) {
      return '$date ${time.isNotEmpty ? time : ''}'.trim();
    }

    final rawDate = _pickFirstValue(order, [
      'createdAt',
      'orderedAt',
      'placedAt',
      'dateTime',
      'timestamp',
      'date',
      'time',
    ]);

    if (rawDate == null) return 'Date not available';

    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();

    int hour = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$month/$day/$year  $hour:$minute $amPm';
  }

  String _itemsText(Map<String, dynamic> order) {
    final dynamic items = _pickFirstValue(order, [
      'items',
      'orderItems',
      'cartItems',
      'menuItems',
      'selectedItems',
    ]);

    if (items is String && items.trim().isNotEmpty) {
      return items;
    }

    if (items is List && items.isNotEmpty) {
      return items.map((item) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] ??
              item['title'] ??
              item['itemName'] ??
              item['label'] ??
              'Item')
              .toString();

          final qty =
          (item['quantity'] ?? item['qty'] ?? item['count'] ?? 1).toString();

          return '$name x$qty';
        }

        return item.toString();
      }).join(', ');
    }

    final summary = _pickFirstValue(order, [
      'cartSummary',
      'summary',
      'itemsText',
      'itemSummary',
      'menu',
    ]);

    if (summary != null) {
      return summary.toString();
    }

    return 'Items not available';
  }

  String _totalText(Map<String, dynamic> order) {
    final total = _pickFirstValue(order, [
      'total',
      'totalPrice',
      'grandTotal',
      'amount',
      'price',
    ]);

    if (total == null) return '0.00';
    return total.toString();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: valueColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _getOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No orders yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = orders[index];

          final business = (order['business'] ?? order['title'] ?? 'Business')
              .toString()
              .trim();

          final status = (order['status'] ?? 'Pending').toString().trim();

          final paymentStatus =
          (order['paymentStatus'] ?? 'Unpaid').toString().trim();

          final paymentMethod =
          (order['paymentMethod'] ?? '').toString().trim();

          final paymentType =
          (order['paymentType'] ?? '').toString().trim();

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          business.isEmpty ? 'Business' : business,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.receipt_long,
                    label: 'Items',
                    value: _itemsText(order),
                  ),
                  _buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'Total',
                    value: '\$${_totalText(order)}',
                  ),
                  _buildInfoRow(
                    icon: Icons.payment,
                    label: 'Payment',
                    value: paymentMethod.isNotEmpty
                        ? '$paymentStatus ($paymentMethod)'
                        : paymentStatus,
                  ),
                  if (paymentType.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.info_outline,
                      label: 'Payment Type',
                      value: paymentType,
                    ),
                  _buildInfoRow(
                    icon: Icons.schedule,
                    label: 'Ordered',
                    value: _formatDate(order),
                  ),
                  if ((order['notes'] ?? '').toString().trim().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.edit_note,
                      label: 'Notes',
                      value: order['notes'].toString().trim(),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const SizedBox.shrink(),
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