import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_data.dart';
import 'notification_data.dart';
import 'local_notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _showFilters = false;
  final ScrollController _ordersScrollController = ScrollController();
  bool _showStats = true;
  double _lastScrollOffset = 0;
  @override
  void initState() {
    super.initState();

    _ordersScrollController.addListener(() {
      final double currentOffset = _ordersScrollController.offset;

      if (currentOffset > _lastScrollOffset + 12 && _showStats) {
        setState(() {
          _showStats = false;
        });
      } else if (currentOffset < _lastScrollOffset - 12 && !_showStats) {
        setState(() {
          _showStats = true;
        });
      }

      _lastScrollOffset = currentOffset;
    });
  }
  String _selectedStatusFilter = 'All';
  String _selectedOrderTypeFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      LocalNotificationService.showNotification(
        title: 'Order Update',
        body: notificationMessage,
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
      NotificationData.addNotification(
        title: 'Order Rejected',
        message: 'Your order was rejected by $business.',
      );

      LocalNotificationService.showNotification(
        title: 'Order Rejected',
        body: 'Your order was rejected by $business.',
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
        message:
        '$business accepted your order. Please pay now using the payment options, then tap "I\'m Here" when you arrive.',
        business: business,
        customer: customer,
        type: 'payment',
      );
      NotificationData.addNotification(
        title: 'Payment Required',
        message:
        '$business accepted your order. Please pay now using the payment options, then tap "I\'m Here" when you arrive.',
      );
      LocalNotificationService.showNotification(
        title: 'Payment Required',
        body:
        '$business accepted your order. Please pay now using the payment options, then tap "I\'m Here" when you arrive.',
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
      NotificationData.addNotification(
        title: 'Payment Received',
        message: 'Payment was confirmed for $customer.',
      );

      LocalNotificationService.showNotification(
        title: 'Payment Received',
        body: 'Payment was confirmed for $customer.',
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
  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange,
    );

    if (picked == null) return;

    setState(() {
      _selectedDateRange = picked;
    });
  }
  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedStatusFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatusFilter = label;
          });
        },
      ),
    );
  }
  Widget _buildOrderTypeChip(String type) {
    final bool isSelected = _selectedOrderTypeFilter == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(type),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedOrderTypeFilter = type;
          });
        },
      ),
    );
  }

  Map<String, dynamic> _getTodayStats() {
    final orders = OrderData.orders;

    int count = 0;
    double totalSales = 0.0;

    final DateTime now = DateTime.now();

    for (final order in orders) {
      DateTime? orderTime;

      if (order['createdAt'] != null) {
        orderTime = DateTime.tryParse(order['createdAt'].toString());
      }

      if (orderTime == null) {
        final String dateText = (order['date'] ?? '').toString().trim();

        if (dateText.isNotEmpty) {
          final parts = dateText.split('/');

          if (parts.length == 3) {
            final int? month = int.tryParse(parts[0]);
            final int? day = int.tryParse(parts[1]);
            final int? year = int.tryParse(parts[2]);

            if (month != null && day != null && year != null) {
              orderTime = DateTime(year, month, day);
            }
          }
        }
      }

      if (orderTime == null) continue;

      if (orderTime.year == now.year &&
          orderTime.month == now.month &&
          orderTime.day == now.day) {
        count++;

        final String totalStr = (order['total'] ?? '0').toString();
        final double value = double.tryParse(totalStr) ?? 0.0;
        totalSales += value;
      }
    }

    return {
      'count': count,
      'sales': totalSales,
    };
  }

  Map<String, dynamic> _getStatsForRange(DateTime startDate) {
    final orders = OrderData.orders;

    int count = 0;
    double totalSales = 0.0;

    final DateTime start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    for (final order in orders) {
      DateTime? orderTime;

      if (order['createdAt'] != null) {
        orderTime = DateTime.tryParse(order['createdAt'].toString());
      }

      if (orderTime == null) {
        final String dateText = (order['date'] ?? '').toString().trim();
        final parts = dateText.split('/');

        if (parts.length == 3) {
          final int? month = int.tryParse(parts[0]);
          final int? day = int.tryParse(parts[1]);
          final int? year = int.tryParse(parts[2]);

          if (month != null && day != null && year != null) {
            orderTime = DateTime(year, month, day);
          }
        }
      }

      if (orderTime == null) continue;

      final DateTime orderDate = DateTime(
        orderTime.year,
        orderTime.month,
        orderTime.day,
      );

      if (orderDate.isBefore(start)) continue;

      count++;

      final String totalStr = (order['total'] ?? '0').toString();
      final double value = double.tryParse(totalStr) ?? 0.0;
      totalSales += value;
    }

    return {
      'count': count,
      'sales': totalSales,
    };
  }
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _formatOrderDateTime(Map<String, dynamic> order, int index) {
    final String createdAt = (order['createdAt'] ?? '').toString().trim();
    if (createdAt.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        final String date =
            '${parsed.month}/${parsed.day}/${parsed.year}';
        final String time = TimeOfDay.fromDateTime(parsed).format(context);
        return '$date $time';
      }
    }

    final String date = (order['date'] ?? '').toString().trim();
    final String time = (order['time'] ?? '').toString().trim();

    if (date.isNotEmpty && time.isNotEmpty) {
      return '$date $time';
    }

    if (date.isNotEmpty) return date;
    if (time.isNotEmpty) return time;

    return 'Order #${index + 1}';
  }

  bool _matchesSearch(Map<String, dynamic> order, int index) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final String business = (order['business'] ?? '').toString().toLowerCase();
    final String customer = (order['customer'] ?? '').toString().toLowerCase();
    final String phone = (order['phone'] ?? '').toString().toLowerCase();
    final String items = (order['items'] ?? '').toString().toLowerCase();
    final String status = (order['status'] ?? '').toString().toLowerCase();
    final String orderDateTime =
    _formatOrderDateTime(order, index).toLowerCase();
    final String paymentMethod = _formatPaymentMethod(order).toLowerCase();
    final String paymentStatus =
    (order['paymentStatus'] ?? '').toString().toLowerCase();

    final String orderNumber = (index + 1).toString();
    final String orderSearchText =
        '#$orderNumber order $orderNumber order #$orderNumber';

    return business.contains(query) ||
        customer.contains(query) ||
        phone.contains(query) ||
        items.contains(query) ||
        status.contains(query) ||
        paymentMethod.contains(query) ||
        paymentStatus.contains(query) ||
        orderDateTime.contains(query) ||
        orderSearchText.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderData.orders;
    final todayStats = _getTodayStats();
    final DateTime now = DateTime.now();

    final weekStats = _getStatsForRange(
      now.subtract(Duration(days: now.weekday - 1)),
    );

    final monthStats = _getStatsForRange(
      DateTime(now.year, now.month, 1),
    );

    final yearStats = _getStatsForRange(
      DateTime(now.year, 1, 1),
    );

    final List<int> filteredIndices = [];
    for (int i = orders.length - 1; i >= 0; i--) {
      final String status =
      (orders[i]['status'] ?? 'Pending').toString().trim();

      final bool matchesStatus =
          _selectedStatusFilter == 'All' || status == _selectedStatusFilter;

      final bool matchesSearch = _matchesSearch(orders[i], i);
      bool matchesOrderType = true;

      if (_selectedOrderTypeFilter != 'All') {
        final order = orders[i];

        final bool isPosOrder = order['orderType'] == 'pos';
        final bool isPayNowOrder = _isPayNowOrder(order);
        final bool isPayAtCounterOrder = _isPayAtCounterOrder(order);

        if (_selectedOrderTypeFilter == 'POS') {
          matchesOrderType = isPosOrder;

        } else if (_selectedOrderTypeFilter == 'Pay Now') {
          matchesOrderType = isPayNowOrder && !isPosOrder;

        } else if (_selectedOrderTypeFilter == 'Pay at Counter') {
          matchesOrderType = isPayAtCounterOrder && !isPosOrder;
        }
      }
      bool matchesDate = true;

      if (_selectedDateRange != null) {
        DateTime? orderTime;

        if (orders[i]['createdAt'] != null) {
          orderTime = DateTime.tryParse(orders[i]['createdAt'].toString());
        }

        if (orderTime == null) {
          final String dateText = (orders[i]['date'] ?? '').toString();
          final parts = dateText.split('/');

          if (parts.length == 3) {
            final m = int.tryParse(parts[0]);
            final d = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);

            if (m != null && d != null && y != null) {
              orderTime = DateTime(y, m, d);
            }
          }
        }

        if (orderTime != null) {
          matchesDate = orderTime.isAfter(
            _selectedDateRange!.start.subtract(const Duration(days: 1)),
          ) &&
              orderTime.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              );
        }
      }

      if (matchesStatus && matchesSearch && matchesDate && matchesOrderType) {
        filteredIndices.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          const SizedBox(height: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showStats
                ? Padding(
              key: const ValueKey('stats-visible'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactStat(
                      title: 'Today',
                      value: '${todayStats['count']} orders',
                      subValue: '\$${todayStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: 'Week',
                      value: '${weekStats['count']} orders',
                      subValue: '\$${weekStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.calendar_view_week,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: 'Month',
                      value: '${monthStats['count']} orders',
                      subValue: '\$${monthStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.calendar_month,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: 'Year',
                      value: '${yearStats['count']} orders',
                      subValue: '\$${yearStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.insights,
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(key: ValueKey('stats-hidden')),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      _showFilters ? Icons.expand_less : Icons.tune,
                      size: 18,
                    ),
                    label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                  ),
                ),
              ],
            ),
          ),

          if (_showFilters) ...[
            const SizedBox(height: 8),

            // STATUS FILTERS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Pending'),
                  _buildFilterChip('Accepted'),
                  _buildFilterChip('Preparing'),
                  _buildFilterChip('Ready'),
                  _buildFilterChip('Completed'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ORDER TYPE FILTERS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildOrderTypeChip('All'),
                  _buildOrderTypeChip('Pay Now'),
                  _buildOrderTypeChip('Pay at Counter'),
                  _buildOrderTypeChip('POS'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search orders',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Date Range',
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    tooltip: 'Clear Date Range',
                    onPressed: _clearDateRange,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filteredIndices.isEmpty
                ? const Center(
              child: Text(
                'No orders found',
                style: TextStyle(fontSize: 16),
              ),
            )
                :ListView.builder(
              controller: _ordersScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredIndices.length,
              itemBuilder: (context, filteredIndex) {
                final int index = filteredIndices[filteredIndex];
                final order = orders[index];

                final String status =
                (order['status'] ?? 'Pending').toString();
                final String business =
                (order['business'] ?? '').toString();
                final String rawItems =
                (order['items'] ?? '').toString().trim();
                final String items =
                rawItems.isNotEmpty ? rawItems : 'No items';
                final String customer =
                (order['customer'] ?? '').toString();
                final String phone = (order['phone'] ?? '').toString();
                final String total = (order['total'] ?? '').toString();

                final String orderType = (order['orderType'] ?? '').toString().toLowerCase();
                final bool isPosOrder = orderType == 'pos' || orderType.contains('pos');
                final bool isHereNow = order['customerAtLocation'] == true;
                final bool transactionComplete =
                    order['transactionComplete'] == true ||
                        status == 'Completed';

                final bool isPayNowOrder = _isPayNowOrder(order);
                final bool isPayAtCounterOrder =
                _isPayAtCounterOrder(order);

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
                final bool isReady = status == 'Ready';
                final bool isCompleted = status == 'Completed';
                final bool isPaid =
                    paymentStatus.toLowerCase() == 'paid';
                final bool isPaymentSent =
                    paymentStatus.toLowerCase() == 'payment sent';

                final bool canStartPreparing = isAccepted &&
                    !isRejected &&
                    !isCompleted &&
                    (isPayAtCounterOrder || isPaid || isPosOrder);

                final bool showSendPaymentOptions = isAccepted &&
                    !isRejected &&
                    !isCompleted &&
                    isPayNowOrder &&
                    !isPaid;

                final bool showPaymentReceived = isAccepted &&
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
                        Row(
                          children: [
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

                            const SizedBox(width: 8),

                            if (index >= orders.length - 3)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoLine(
                          'Order',
                          '#${index + 1} • ${_formatOrderDateTime(order, index)}',
                          valueColor: Colors.grey.shade800,
                          valueWeight: FontWeight.w600,
                        ),
                        _infoLine('Items', items),
                        _infoLine(
                            'Customer', customer.isEmpty ? 'N/A' : customer),
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
                        if ((order['arrivedAt'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty)
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
                        if ((order['customerLatitude'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty &&
                            (order['customerLongitude'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty)
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
                                onPressed: () =>
                                    _showPaymentOptionsDialog(index),
                                child: const Text('Payment Options'),
                              ),
                            if (showPaymentReceived)
                              OutlinedButton(
                                onPressed: () =>
                                    _markPaymentReceived(index),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: Colors.orange.shade700),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}