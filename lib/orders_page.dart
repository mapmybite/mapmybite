import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_data.dart';
import 'notification_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  void _updateStatus(int index, String newStatus) {
    setState(() {
      OrderData.orders[index]['status'] = newStatus;

      final order = OrderData.orders[index];
      final bool isPayAtCounter = _isPayAtCounterOrder(order);
      final String business =
      (OrderData.orders[index]['business'] ?? '').toString();
      final String customer =
      (OrderData.orders[index]['customer'] ?? '').toString();

      if (newStatus == 'Completed') {
        OrderData.orders[index]['transactionComplete'] = true;

        if (isPayAtCounter) {
          OrderData.orders[index]['paymentStatus'] = 'Paid';
        }
        NotificationData.removeNotificationsWhere(
          messageContains: customer,
        );
      }



      String notificationMessage = 'Your order status is now $newStatus.';

      if (newStatus == 'Accepted') {
        notificationMessage = 'Your order was accepted by $business.';
      } else if (newStatus == 'Preparing') {
        notificationMessage = 'Your order is now being prepared.';
      } else if (newStatus == 'Ready') {
        if (isPayAtCounter) {
          notificationMessage =
          'Your order is ready. Please pay at counter and pick up your order.';
        } else {
          notificationMessage = 'Your order is ready for pickup.';
        }
      } else if (newStatus == 'Completed') {
        notificationMessage = 'Your order was completed. Thank you!';
      } else if (newStatus == 'Rejected') {
        notificationMessage = 'Your order was rejected.';
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated: $newStatus')),
      );

      NotificationData.addNotification(
        title: 'Order Update',
        message: notificationMessage,
      );

      OrderData.addNotification(
        audience: 'customer',
        title: 'Order Update',
        message: notificationMessage,
        business: business,
        customer: customer,
        type: 'order_status',
      );
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order marked $newStatus')),
    );
  }

  void _rejectOrder(int index) {
    setState(() {
      OrderData.orders[index]['status'] = 'Rejected';
      OrderData.orders[index]['transactionComplete'] = false;

      final String business =
      (OrderData.orders[index]['business'] ?? '').toString();
      final String customer =
      (OrderData.orders[index]['customer'] ?? '').toString();

      OrderData.addNotification(
        audience: 'customer',
        title: 'Order Rejected',
        message: 'Your order was rejected by $business.',
        business: business,
        customer: customer,
        type: 'order_status',
      );
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order rejected')),
    );
  }

  void _markPaymentRequestSent(int index) {
    setState(() {
      OrderData.orders[index]['paymentStatus'] = 'Payment Request Sent';

      final String business =
      (OrderData.orders[index]['business'] ?? '').toString();
      final String customer =
      (OrderData.orders[index]['customer'] ?? '').toString();

      OrderData.addNotification(
        audience: 'customer',
        title: 'Payment Required',
        message: '$business accepted your order. Please pay now using the payment options, then tap "I\'m Here" when you arrive.',
        business: business,
        customer: customer,
        type: 'payment',
      );
      NotificationData.addNotification(
        title: 'Payment Required',
        message: '$business accepted your order. Please pay now using the payment options, then tap "I\'m Here" when you arrive.',
      );
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment options sent to customer')),
    );
  }

  void _markPaymentReceived(int index) {
    setState(() {
      OrderData.orders[index]['paymentStatus'] = 'Paid';

      final String business =
      (OrderData.orders[index]['business'] ?? '').toString();
      final String customer =
      (OrderData.orders[index]['customer'] ?? '').toString();

      OrderData.addNotification(
        audience: 'customer',
        title: 'Payment Confirmed',
        message: '$business confirmed your payment.',
        business: business,
        customer: customer,
        type: 'payment',
      );

      OrderData.addNotification(
        audience: 'owner',
        title: 'Payment Received',
        message: 'Payment was confirmed for $customer.',
        business: business,
        customer: customer,
        type: 'payment',
      );
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment confirmed')),
    );
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
  Future<void> _openArrivalDirections({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Widget _buildArrivalMapCard(Map<String, dynamic> order) {
    final double? lat = double.tryParse(
      (order['customerLatitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (order['customerLongitude'] ?? '').toString(),
    );

    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }

    final String arrivedAt = (order['arrivedAt'] ?? '').toString().trim();
    final String distanceText = order['arrivalDistanceMeters'] != null
        ? '${((order['arrivalDistanceMeters'] as num).toDouble()).toStringAsFixed(0)} m away'
        : 'Customer checked in';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Arrival Snapshot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (arrivedAt.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Checked in at $arrivedAt',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('customer_arrival'),
                    position: LatLng(lat, lng),
                    infoWindow: const InfoWindow(title: 'Customer location'),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                liteModeEnabled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openArrivalDirections(
                  latitude: lat,
                  longitude: lng,
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Open in Maps'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPayNowOrder(Map<String, dynamic> order) {
    final String paymentType =
    (order['paymentType'] ?? '').toString().trim().toLowerCase();
    final String paymentMethod =
    (order['paymentMethod'] ?? '').toString().trim().toLowerCase();

    return paymentType == 'pay_now' ||
        paymentMethod == 'pay_now' ||
        paymentMethod == 'cash_app' ||
        paymentMethod == 'zelle' ||
        paymentMethod == 'venmo' ||
        paymentMethod == 'square' ||
        paymentMethod == 'card';
  }

  bool _isPayAtCounterOrder(Map<String, dynamic> order) {
    final String paymentType =
    (order['paymentType'] ?? '').toString().trim().toLowerCase();
    final String paymentMethod =
    (order['paymentMethod'] ?? '').toString().trim().toLowerCase();

    return paymentType == 'pay_later' ||
        paymentType == 'pay_at_counter' ||
        paymentMethod == 'pay_later' ||
        paymentMethod == 'pay_at_counter' ||
        paymentMethod == 'cash';
  }

  String _formatPaymentMethod(Map<String, dynamic> order) {
    final String paymentType =
    (order['paymentType'] ?? '').toString().trim().toLowerCase();
    final String raw =
    (order['paymentMethod'] ?? '').toString().trim().toLowerCase();

    if (raw == 'cash') return 'Cash';
    if (raw == 'card') return 'Card';
    if (raw == 'cash_app') return 'Cash App';
    if (raw == 'zelle') return 'Zelle';
    if (raw == 'venmo') return 'Venmo';
    if (raw == 'square') return 'Square';
    if (raw == 'pay_now') return 'Pay Now';
    if (raw == 'pay_later' || raw == 'pay_at_counter') return 'Pay at Counter';

    if (paymentType == 'pay_later' || paymentType == 'pay_at_counter') {
      return 'Pay at Counter';
    }

    if (paymentType == 'pay_now') {
      return 'Pay Now';
    }

    return raw.isEmpty ? 'Not selected' : raw;
  }

  String _displayPaymentStatus(
      Map<String, dynamic> order,
      String status,
      bool isPosOrder,
      bool isPayNowOrder,
      bool isPayAtCounterOrder,
      ) {
    final String raw = (order['paymentStatus'] ?? '').toString().trim();

    if (raw.isNotEmpty) {
      return raw;
    }

    if (status == 'Completed' || isPosOrder) {
      return 'Paid';
    }

    if (isPayAtCounterOrder) {
      return 'Pay at Counter';
    }

    if (isPayNowOrder) {
      if (status == 'Pending') return 'Waiting for owner approval';
      if (status == 'Accepted') return 'Waiting to send payment options';
      return 'Unpaid';
    }

    return 'Unpaid';
  }

  Widget _infoLine(
      String label,
      String value, {
        Color? valueColor,
        FontWeight valueWeight = FontWeight.w500,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueWeight,
              ),
            ),
          ],
        ),
      ),
    );
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
    final String square = (order['square'] ?? '').toString().trim();

    final bool hasAnyPaymentMethod = cashApp.isNotEmpty ||
        zelle.isNotEmpty ||
        venmo.isNotEmpty ||
        square.isNotEmpty;

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
                  'Send customer one of these payment options:',
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
                  _paymentRow(
                    label: 'Square',
                    value: square,
                    icon: Icons.point_of_sale,
                    color: Colors.black87,
                    openUrl: square.isNotEmpty ? square : null,
                  ),
                ] else ...[
                  const Text('No payment methods added'),
                ],
                const SizedBox(height: 14),
                const Text(
                  'After customer pays, tap "Payment Received".',
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
                _markPaymentRequestSent(index);
              },
              child: const Text('Send Payment Request'),
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
      body: orders.isEmpty
          ? const Center(
        child: Text(
          'No orders yet',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          final String status = (order['status'] ?? 'Pending').toString();
          final String business = (order['business'] ?? '').toString();
          final String items = (order['items'] ?? '').toString();
          final String customer = (order['customer'] ?? '').toString();
          final String phone = (order['phone'] ?? '').toString();
          final String total = (order['total'] ?? '').toString();

          final bool isPosOrder = order['orderType'] == 'pos';
          final bool isHereNow = order['customerAtLocation'] == true;
          final bool transactionComplete =
              order['transactionComplete'] == true ||
                  status == 'Completed';

          final bool isPayNowOrder = _isPayNowOrder(order);
          final bool isPayAtCounterOrder = _isPayAtCounterOrder(order);

          final String paymentMethod = _formatPaymentMethod(order);

          final String paymentStatus = _displayPaymentStatus(
            order,
            status,
            isPosOrder,
            isPayNowOrder,
            isPayAtCounterOrder,
          );

          final bool isRejected = status == 'Rejected';
          final bool isAccepted = status == 'Accepted';
          final bool isPreparing = status == 'Preparing';
          final bool isArrived = order['customerAtLocation'] == true;
          final bool isReady = status == 'Ready';
          final bool isCompleted = status == 'Completed';
          final bool isPaid = paymentStatus.toLowerCase() == 'paid';
          final bool isPaymentSent =
              paymentStatus.toLowerCase() == 'payment sent';

          final bool canStartPreparing =
              isAccepted &&
                  !isRejected &&
                  !isCompleted &&
                  (isPayAtCounterOrder || isPaid || isPosOrder);

          final bool showSendPaymentOptions =
              isAccepted &&
                  !isRejected &&
                  !isCompleted &&
                  isPayNowOrder &&
                  !isPaid;

          final bool showPaymentReceived =
              isAccepted &&
                  !isRejected &&
                  !isCompleted &&
                  isPayNowOrder &&
                  isPaymentSent;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPosOrder
                        ? 'POS Order'
                        : isHereNow
                        ? 'CUSTOMER IS HERE'
                        : 'Online Order',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPosOrder
                          ? Colors.blue
                          : isHereNow
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoLine('Items', items),
                  _infoLine('Customer', customer.isEmpty ? 'N/A' : customer),
                  _infoLine('Phone', phone.isEmpty ? 'N/A' : phone),
                  _infoLine(
                    'Status',
                    status,
                    valueColor: isRejected
                        ? Colors.red
                        : isCompleted
                        ? Colors.green
                        : Colors.black87,
                  ),
                  _infoLine(
                    'Payment Method',
                    paymentMethod,
                    valueColor: Colors.indigo,
                  ),
                  _infoLine(
                    'Payment Status',
                    paymentStatus,
                    valueColor: isPaid
                        ? Colors.green
                        : isPaymentSent
                        ? Colors.blue
                        : isPayAtCounterOrder
                        ? Colors.orange
                        : Colors.redAccent,
                  ),
                  if (isHereNow)
                    _infoLine(
                      'Skip the Line',
                      'Customer is here',
                      valueColor: Colors.green,
                      valueWeight: FontWeight.bold,
                    ),
                  if ((order['arrivedAt'] ?? '').toString().trim().isNotEmpty)
                    _infoLine(
                      'Arrived At',
                      (order['arrivedAt'] ?? '').toString(),
                      valueColor: Colors.green,
                      valueWeight: FontWeight.w600,
                    ),
                  if (order['arrivalDistanceMeters'] != null)
                    _infoLine(
                      'Distance',
                      '${((order['arrivalDistanceMeters'] as num).toDouble()).toStringAsFixed(0)} m',
                      valueColor: Colors.green,
                      valueWeight: FontWeight.w600,
                    ),
                  if ((order['customerLatitude'] ?? '').toString().trim().isNotEmpty &&
                      (order['customerLongitude'] ?? '').toString().trim().isNotEmpty)
                    _buildArrivalMapCard(order),
                  if (total.trim().isNotEmpty)
                    _infoLine(
                      'Total',
                      '\$$total',
                      valueWeight: FontWeight.bold,
                    ),
                  if (transactionComplete)
                    _infoLine(
                      'Transaction',
                      'Complete',
                      valueColor: Colors.green,
                      valueWeight: FontWeight.bold,
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: status == 'Pending'
                            ? () => _updateStatus(index, 'Accepted')
                            : null,
                        child: const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: status == 'Pending'
                            ? () => _rejectOrder(index)
                            : null,
                        child: const Text('Reject'),
                      ),
                      ElevatedButton(
                        onPressed: canStartPreparing
                            ? () => _updateStatus(index, 'Preparing')
                            : null,
                        child: const Text('Preparing'),
                      ),
                      ElevatedButton(
                        onPressed: isPreparing
                            ? () => _updateStatus(index, 'Ready')
                            : null,
                        child: const Text('Ready'),
                      ),
                      ElevatedButton(
                        onPressed: isReady
                            ? () => _updateStatus(index, 'Completed')
                            : null,
                        child: const Text('Complete'),
                      ),
                      if (showSendPaymentOptions)
                        OutlinedButton(
                          onPressed: () => _showPaymentOptionsDialog(index),
                          child: const Text('Payment Options'),
                        ),
                      if (showPaymentReceived)
                        OutlinedButton(
                          onPressed: () => _markPaymentReceived(index),
                          child: const Text('Payment Received'),
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