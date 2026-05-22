import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_text.dart';
import 'order_data.dart';

class CustomerOrderHistoryPage extends StatefulWidget {
  const CustomerOrderHistoryPage({super.key});

  @override
  State<CustomerOrderHistoryPage> createState() =>
      _CustomerOrderHistoryPageState();
}

class _CustomerOrderHistoryPageState extends State<CustomerOrderHistoryPage> {
  final FlutterTts _ordersTts = FlutterTts();
  String _speakingOrderId = '';
  bool _isSpeakingOrder = false;

  List<Map<String, dynamic>> _getOrders() {
    return OrderData.getCustomerOrders();
  }

  @override
  void dispose() {
    _ordersTts.stop();
    super.dispose();
  }
Future<void> _setupVoice() async {
  switch (AppText.language) {
    case 'es':
      await _ordersTts.setLanguage('es-ES');
      break;
    case 'hi':
      await _ordersTts.setLanguage('hi-IN');
      break;
    case 'pa':
      await _ordersTts.setLanguage('pa-IN');
      break;
    default:
      await _ordersTts.setLanguage('en-US');
  }

  await _ordersTts.setSpeechRate(0.43);
  await _ordersTts.setPitch(1.08);
  await _ordersTts.setVolume(1.0);
}
 Future<void> _speak(String orderId, String text) async {
   final clean = text.trim();
   if (clean.isEmpty) return;

   await _setupVoice();

   if (_isSpeakingOrder && _speakingOrderId == orderId) {
     await _ordersTts.stop();
     if (!mounted) return;
     setState(() {
       _isSpeakingOrder = false;
       _speakingOrderId = '';
     });
     return;
   }

   await _ordersTts.stop();

   if (!mounted) return;
   setState(() {
     _isSpeakingOrder = true;
     _speakingOrderId = orderId;
   });

   await _ordersTts.speak(clean);

   _ordersTts.setCompletionHandler(() {
     if (!mounted) return;
     setState(() {
       _isSpeakingOrder = false;
       _speakingOrderId = '';
     });
   });

   _ordersTts.setCancelHandler(() {
     if (!mounted) return;
     setState(() {
       _isSpeakingOrder = false;
       _speakingOrderId = '';
     });
   });
 }

  String _txt(String key) {
    switch (AppText.language) {
      case 'es':
        return {
          'myOrders': 'Mis pedidos',
          'noOrders': 'Todavía no hay pedidos.',
          'business': 'Negocio',
          'items': 'Artículos',
          'total': 'Total',
          'payment': 'Pago',
          'paymentType': 'Tipo de pago',
          'ordered': 'Pedido',
          'notes': 'Notas',
          'readOrder': 'Leer pedido',
          'dateNotAvailable': 'Fecha no disponible',
          'itemsNotAvailable': 'Artículos no disponibles',
          'pending': 'Pendiente',
          'accepted': 'Aceptado',
          'preparing': 'Preparando',
          'ready': 'Listo',
          'completed': 'Completado',
          'cancelled': 'Cancelado',
          'rejected': 'Rechazado',
          'unpaid': 'No pagado',
          'paid': 'Pagado',
          'businessFallback': 'Negocio',
          'itemFallback': 'Artículo',
        }[key] ??
            key;
      case 'hi':
        return {
          'myOrders': 'मेरे ऑर्डर',
          'noOrders': 'अभी कोई ऑर्डर नहीं है।',
          'business': 'बिज़नेस',
          'items': 'आइटम',
          'total': 'कुल',
          'payment': 'पेमेंट',
          'paymentType': 'पेमेंट प्रकार',
          'ordered': 'ऑर्डर समय',
          'notes': 'नोट्स',
          'readOrder': 'ऑर्डर सुनें',
          'dateNotAvailable': 'तारीख उपलब्ध नहीं है',
          'itemsNotAvailable': 'आइटम उपलब्ध नहीं हैं',
          'pending': 'पेंडिंग',
          'accepted': 'स्वीकार किया गया',
          'preparing': 'तैयार हो रहा है',
          'ready': 'तैयार',
          'completed': 'पूरा हुआ',
          'cancelled': 'रद्द',
          'rejected': 'रिजेक्ट किया गया',
          'unpaid': 'पेमेंट बाकी',
          'paid': 'पेमेंट हो गया',
          'businessFallback': 'बिज़नेस',
          'itemFallback': 'आइटम',
        }[key] ??
            key;
      case 'pa':
        return {
          'myOrders': 'ਮੇਰੇ ਆਰਡਰ',
          'noOrders': 'ਹਾਲੇ ਕੋਈ ਆਰਡਰ ਨਹੀਂ।',
          'business': 'ਬਿਜ਼ਨਸ',
          'items': 'ਆਈਟਮਾਂ',
          'total': 'ਕੁੱਲ',
          'payment': 'ਪੇਮੈਂਟ',
          'paymentType': 'ਪੇਮੈਂਟ ਕਿਸਮ',
          'ordered': 'ਆਰਡਰ ਸਮਾਂ',
          'notes': 'ਨੋਟਸ',
          'readOrder': 'ਆਰਡਰ ਸੁਣੋ',
          'dateNotAvailable': 'ਤਾਰੀਖ ਉਪਲਬਧ ਨਹੀਂ',
          'itemsNotAvailable': 'ਆਈਟਮ ਉਪਲਬਧ ਨਹੀਂ',
          'pending': 'ਪੈਂਡਿੰਗ',
          'accepted': 'ਸਵੀਕਾਰ ਕੀਤਾ',
          'preparing': 'ਤਿਆਰ ਹੋ ਰਿਹਾ ਹੈ',
          'ready': 'ਤਿਆਰ',
          'completed': 'ਪੂਰਾ ਹੋਇਆ',
          'cancelled': 'ਰੱਦ',
          'rejected': 'ਰਿਜੈਕਟ ਕੀਤਾ',
          'unpaid': 'ਪੇਮੈਂਟ ਬਾਕੀ',
          'paid': 'ਪੇਮੈਂਟ ਹੋ ਗਈ',
          'businessFallback': 'ਬਿਜ਼ਨਸ',
          'itemFallback': 'ਆਈਟਮ',
        }[key] ??
            key;
      default:
        return {
          'myOrders': 'My Orders',
          'noOrders': 'No orders yet.',
          'business': 'Business',
          'items': 'Items',
          'total': 'Total',
          'payment': 'Payment',
          'paymentType': 'Payment Type',
          'ordered': 'Ordered',
          'notes': 'Notes',
          'readOrder': 'Read order',
          'dateNotAvailable': 'Date not available',
          'itemsNotAvailable': 'Items not available',
          'pending': 'Pending',
          'accepted': 'Accepted',
          'preparing': 'Preparing',
          'ready': 'Ready',
          'completed': 'Completed',
          'cancelled': 'Cancelled',
          'rejected': 'Rejected',
          'unpaid': 'Unpaid',
          'paid': 'Paid',
          'businessFallback': 'Business',
          'itemFallback': 'Item',
        }[key] ??
            key;
    }
  }

  String _statusText(String status) {
    final clean = status.trim();
    switch (clean.toLowerCase()) {
      case 'pending':
        return _txt('pending');
      case 'accepted':
        return _txt('accepted');
      case 'preparing':
        return _txt('preparing');
      case 'ready':
        return _txt('ready');
      case 'completed':
        return _txt('completed');
      case 'cancelled':
        return _txt('cancelled');
      case 'rejected':
        return _txt('rejected');
      default:
        return clean.isEmpty ? _txt('pending') : clean;
    }
  }

  String _paymentStatusText(String status) {
    final clean = status.trim();
    switch (clean.toLowerCase()) {
      case 'paid':
        return _txt('paid');
      case 'unpaid':
        return _txt('unpaid');
      default:
        return clean.isEmpty ? _txt('unpaid') : clean;
    }
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

    if (rawDate == null) return _txt('dateNotAvailable');

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
                  _txt('itemFallback'))
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

    return _txt('itemsNotAvailable');
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

  String _buildOrderSpeech(Map<String, dynamic> order) {
    final business = (order['business'] ?? order['title'] ?? _txt('businessFallback'))
        .toString()
        .trim();

    final status = _statusText((order['status'] ?? 'Pending').toString());
    final items = _itemsText(order);
    final total = _totalText(order);

    final rawPaymentStatus =
        (order['paymentStatus'] ?? _txt('unpaid')).toString().trim();
    final paymentStatus = _paymentStatusText(rawPaymentStatus);

    final paymentMethod = (order['paymentMethod'] ?? '').toString().trim();
    final ordered = _formatDate(order);

    switch (AppText.language) {
      case 'es':
        return 'Pedido de ${business.isEmpty ? _txt('businessFallback') : business}. Estado: $status. Artículos: $items. Total: $total dólares. Pago: $paymentStatus${paymentMethod.isNotEmpty ? ' por $paymentMethod' : ''}. Pedido: $ordered.';
      case 'hi':
        return '${business.isEmpty ? _txt('businessFallback') : business} का ऑर्डर। स्टेटस: $status। आइटम: $items। कुल: $total डॉलर। पेमेंट: $paymentStatus${paymentMethod.isNotEmpty ? ' $paymentMethod से' : ''}। ऑर्डर समय: $ordered।';
      case 'pa':
        return '${business.isEmpty ? _txt('businessFallback') : business} ਦਾ ਆਰਡਰ। ਸਟੇਟਸ: $status। ਆਈਟਮਾਂ: $items। ਕੁੱਲ: $total ਡਾਲਰ। ਪੇਮੈਂਟ: $paymentStatus${paymentMethod.isNotEmpty ? ' $paymentMethod ਨਾਲ' : ''}। ਆਰਡਰ ਸਮਾਂ: $ordered।';
      default:
        return 'Order from ${business.isEmpty ? _txt('businessFallback') : business}. Status: $status. Items: $items. Total: $total dollars. Payment: $paymentStatus${paymentMethod.isNotEmpty ? ' by $paymentMethod' : ''}. Ordered: $ordered.';
    }
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
      case 'rejected':
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
        title: Text(
          _txt('myOrders'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _txt('noOrders'),
                  style: const TextStyle(
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

                final business =
                    (order['business'] ?? order['title'] ?? _txt('businessFallback'))
                        .toString()
                        .trim();

                final status = (order['status'] ?? 'Pending').toString().trim();
                final displayStatus = _statusText(status);

                final paymentStatus =
                    (order['paymentStatus'] ?? _txt('unpaid')).toString().trim();
                final displayPaymentStatus = _paymentStatusText(paymentStatus);

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
                                business.isEmpty
                                    ? _txt('businessFallback')
                                    : business,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _txt('readOrder'),
                              onPressed: () => _speak(
                                '${business}_${index}',
                                _buildOrderSpeech(order),
                              ),
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.orange,
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
                                displayStatus,
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
                          label: _txt('items'),
                          value: _itemsText(order),
                        ),
                        _buildInfoRow(
                          icon: Icons.attach_money,
                          label: _txt('total'),
                          value: '\$${_totalText(order)}',
                        ),
                        _buildInfoRow(
                          icon: Icons.payment,
                          label: _txt('payment'),
                          value: paymentMethod.isNotEmpty
                              ? '$displayPaymentStatus ($paymentMethod)'
                              : displayPaymentStatus,
                        ),
                        if (paymentType.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.info_outline,
                            label: _txt('paymentType'),
                            value: paymentType,
                          ),
                        _buildInfoRow(
                          icon: Icons.schedule,
                          label: _txt('ordered'),
                          value: _formatDate(order),
                        ),
                        if ((order['notes'] ?? '').toString().trim().isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.edit_note,
                            label: _txt('notes'),
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
