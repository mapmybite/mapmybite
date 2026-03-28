import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final orders = OrderData.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: orders.isEmpty
          ? const Center(
        child: Text(
          'No orders submitted yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final String status = order['status'] ?? 'Pending';

          Color statusColor;
          Color statusBg;

          switch (status) {
            case 'Accepted':
              statusColor = Colors.blue;
              statusBg = Colors.blue.shade100;
              break;
            case 'Ready':
              statusColor = Colors.green;
              statusBg = Colors.green.shade100;
              break;
            case 'Completed':
              statusColor = Colors.grey;
              statusBg = Colors.grey.shade300;
              break;
            default:
              statusColor = Colors.orange;
              statusBg = Colors.orange.shade100;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order['business'] ?? '',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Customer', order['customer'] ?? ''),
                    _infoRow('Phone', order['phone'] ?? ''),
                    _infoRow('Items', order['items'] ?? ''),
                    _infoRow('Quantity', order['quantity'] ?? ''),
                    _infoRow('Date', order['date'] ?? ''),
                    _infoRow('Time', order['time'] ?? ''),
                    _infoRow('Notes', order['notes'] ?? ''),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: status == 'Pending'
                              ? () => _updateStatus(index, 'Accepted')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.blue.shade100,
                          ),
                          child: const Text('Accept'),
                        ),
                        ElevatedButton(
                          onPressed: status == 'Accepted'
                              ? () => _updateStatus(index, 'Ready')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.green.shade100,
                          ),
                          child: const Text('Ready'),
                        ),
                        ElevatedButton(
                          onPressed: status == 'Ready'
                              ? () => _updateStatus(index, 'Completed')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.grey.shade300,
                          ),
                          child: const Text('Complete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}