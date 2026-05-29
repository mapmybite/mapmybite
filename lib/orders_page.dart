import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_data.dart';
import 'notification_data.dart';
import 'local_notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'owner_customer_data.dart';
import 'app_text.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FlutterTts _ordersTts = FlutterTts();
  String _speakingOrderId = '';
  bool _isSpeakingOrder = false;

  bool _showFilters = false;
  final ScrollController _ordersScrollController = ScrollController();
  bool _showStats = true;
  double _lastScrollOffset = 0;
  String _receiptLine() {
    return '--------------------------------\n';
  }

  String _receiptRow(String left, String right) {
    final cleanLeft = left.length > 16 ? left.substring(0, 16) : left;
    final cleanRight = right.length > 14 ? right.substring(0, 14) : right;

    final spaces = 32 - cleanLeft.length - cleanRight.length;
    return '$cleanLeft${' ' * (spaces > 1 ? spaces : 1)}$cleanRight\n';
  }

  Future<void> _printPosReceipt(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('saved_printer_mac');

    if (savedMac != null && savedMac.isNotEmpty) {
      await PrintBluetoothThermal.connect(macPrinterAddress: savedMac);
    }

    final connected = await PrintBluetoothThermal.connectionStatus;

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected')),
      );
      return;
    }

    final receipt = StringBuffer();

    receipt.writeln('          MAPMYBITE');
    receipt.writeln('        POS RECEIPT');
    receipt.write(_receiptLine());
    receipt.writeln('Business: ${order['business'] ?? ''}');
    receipt.writeln('Customer: ${order['customer'] ?? ''}');

    if ((order['phone'] ?? '').toString().trim().isNotEmpty) {
      receipt.writeln('Phone: ${order['phone']}');
    }

    receipt.writeln('Date: ${order['date'] ?? ''} ${order['time'] ?? ''}');
    receipt.write(_receiptLine());

    receipt.writeln('ITEMS');
    receipt.write(_receiptLine());
    receipt.writeln(order['items'] ?? '');

    receipt.write(_receiptLine());
    receipt.write(_receiptRow('Payment', '${order['paymentMethod'] ?? ''}'));
    receipt.write(_receiptRow('TOTAL', '\$${order['total'] ?? ''}'));

    if ((order['cashReceived'] ?? '').toString().trim().isNotEmpty) {
      receipt.write(_receiptRow('Cash', '\$${order['cashReceived']}'));
      receipt.write(_receiptRow('Change', '\$${order['changeDue']}'));
    }

    if ((order['notes'] ?? '').toString().trim().isNotEmpty) {
      receipt.write(_receiptLine());
      receipt.writeln('Notes: ${order['notes']}');
    }

    receipt.write(_receiptLine());
    receipt.writeln('     Thank you for your order!');
    receipt.writeln('        Powered by MapMyBite');
    receipt.writeln('');
    receipt.writeln('');
    receipt.writeln('');
    receipt.writeln('');

    await PrintBluetoothThermal.writeBytes(receipt.toString().codeUnits);
  }

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
    _ordersTts.stop();
    _searchController.dispose();
    _ordersScrollController.dispose();
    super.dispose();
  }

  String _txt(String key) {
    switch (AppText.language) {
      case 'es':
        return {
          'orders': 'Pedidos',
          'orderWord': 'pedidos',
          'today': 'Hoy',
          'week': 'Semana',
          'month': 'Mes',
          'year': 'Año',
          'showFilters': 'Mostrar filtros',
          'hideFilters': 'Ocultar filtros',
          'searchOrders': 'Buscar pedidos',
          'dateRange': 'Rango de fechas',
          'clearDateRange': 'Borrar rango',
          'noOrdersFound': 'No se encontraron pedidos',
          'all': 'Todos',
          'pending': 'Pendiente',
          'accepted': 'Aceptado',
          'preparing': 'Preparando',
          'ready': 'Listo',
          'completed': 'Completado',
          'rejected': 'Rechazado',
          'payNow': 'Pagar ahora',
          'payAtCounter': 'Pagar en mostrador',
          'pos': 'POS',
          'posOrder': 'Pedido POS',
          'onlineOrder': 'Pedido en línea',
          'customerIsHere': 'EL CLIENTE ESTÁ AQUÍ',
          'new': 'NUEVO',
          'order': 'Pedido',
          'items': 'Artículos',
          'customer': 'Cliente',
          'phone': 'Teléfono',
          'status': 'Estado',
          'paymentMethod': 'Método de pago',
          'paymentStatus': 'Estado de pago',
          'skipLine': 'Saltar la fila',
          'customerHere': 'El cliente está aquí',
          'arrivedAt': 'Llegó a las',
          'distance': 'Distancia',
          'customerLocationReceived': 'Ubicación del cliente recibida',
          'viewMap': 'Ver mapa',
          'total': 'Total',
          'cashReceived': 'Efectivo recibido',
          'changeDue': 'Cambio',
          'transaction': 'Transacción',
          'completeWord': 'Completa',
          'accept': 'Aceptar',
          'reject': 'Rechazar',
          'complete': 'Completar',
          'paymentOptions': 'Opciones de pago',
          'paymentReceived': 'Pago recibido',
          'share': 'Compartir',
          'call': 'Llamar',
          'returning': 'Regresa',
          'visits': 'visitas',
          'newCustomer': 'Cliente nuevo',
          'reward': 'Recompensa',
          'noItems': 'Sin artículos',
          'notSelected': 'No seleccionado',
          'unpaid': 'No pagado',
          'paid': 'Pagado',
          'waitingApproval': 'Esperando aprobación del dueño',
          'waitingPaymentOptions': 'Esperando enviar opciones de pago',
          'readOrder': 'Leer pedido',
        }[key] ?? key;
      case 'hi':
        return {
          'orders': 'ऑर्डर',
          'orderWord': 'ऑर्डर',
          'today': 'आज',
          'week': 'हफ़्ता',
          'month': 'महीना',
          'year': 'साल',
          'showFilters': 'फ़िल्टर दिखाएँ',
          'hideFilters': 'फ़िल्टर छुपाएँ',
          'searchOrders': 'ऑर्डर खोजें',
          'dateRange': 'तारीख रेंज',
          'clearDateRange': 'तारीख रेंज हटाएँ',
          'noOrdersFound': 'कोई ऑर्डर नहीं मिला',
          'all': 'सभी',
          'pending': 'पेंडिंग',
          'accepted': 'स्वीकार किया',
          'preparing': 'तैयार हो रहा है',
          'ready': 'तैयार',
          'completed': 'पूरा हुआ',
          'rejected': 'रिजेक्ट',
          'payNow': 'अभी पे करें',
          'payAtCounter': 'काउंटर पर पे करें',
          'pos': 'POS',
          'posOrder': 'POS ऑर्डर',
          'onlineOrder': 'ऑनलाइन ऑर्डर',
          'customerIsHere': 'ग्राहक यहाँ है',
          'new': 'नया',
          'order': 'ऑर्डर',
          'items': 'आइटम',
          'customer': 'ग्राहक',
          'phone': 'फ़ोन',
          'status': 'स्टेटस',
          'paymentMethod': 'पेमेंट तरीका',
          'paymentStatus': 'पेमेंट स्टेटस',
          'skipLine': 'लाइन छोड़ें',
          'customerHere': 'ग्राहक यहाँ है',
          'arrivedAt': 'आया समय',
          'distance': 'दूरी',
          'customerLocationReceived': 'ग्राहक लोकेशन मिली',
          'viewMap': 'मैप देखें',
          'total': 'कुल',
          'cashReceived': 'कैश मिला',
          'changeDue': 'बकाया चेंज',
          'transaction': 'लेन-देन',
          'completeWord': 'पूरा',
          'accept': 'स्वीकार',
          'reject': 'रिजेक्ट',
          'complete': 'पूरा करें',
          'paymentOptions': 'पेमेंट विकल्प',
          'paymentReceived': 'पेमेंट मिला',
          'share': 'शेयर',
          'call': 'कॉल',
          'returning': 'वापस आया',
          'visits': 'विज़िट',
          'newCustomer': 'नया ग्राहक',
          'reward': 'रिवॉर्ड',
          'noItems': 'कोई आइटम नहीं',
          'notSelected': 'चुना नहीं',
          'unpaid': 'पेमेंट बाकी',
          'paid': 'पेमेंट हो गया',
          'waitingApproval': 'ओनर अप्रूवल का इंतज़ार',
          'waitingPaymentOptions': 'पेमेंट विकल्प भेजने का इंतज़ार',
          'readOrder': 'ऑर्डर सुनें',
        }[key] ?? key;
      case 'pa':
        return {
          'orders': 'ਆਰਡਰ',
          'orderWord': 'ਆਰਡਰ',
          'today': 'ਅੱਜ',
          'week': 'ਹਫ਼ਤਾ',
          'month': 'ਮਹੀਨਾ',
          'year': 'ਸਾਲ',
          'showFilters': 'ਫਿਲਟਰ ਵੇਖਾਓ',
          'hideFilters': 'ਫਿਲਟਰ ਲੁਕਾਓ',
          'searchOrders': 'ਆਰਡਰ ਖੋਜੋ',
          'dateRange': 'ਤਾਰੀਖ ਰੇਂਜ',
          'clearDateRange': 'ਤਾਰੀਖ ਰੇਂਜ ਹਟਾਓ',
          'noOrdersFound': 'ਕੋਈ ਆਰਡਰ ਨਹੀਂ ਮਿਲਿਆ',
          'all': 'ਸਾਰੇ',
          'pending': 'ਪੈਂਡਿੰਗ',
          'accepted': 'ਸਵੀਕਾਰ ਕੀਤਾ',
          'preparing': 'ਤਿਆਰ ਹੋ ਰਿਹਾ',
          'ready': 'ਤਿਆਰ',
          'completed': 'ਪੂਰਾ ਹੋਇਆ',
          'rejected': 'ਰਿਜੈਕਟ',
          'payNow': 'ਹੁਣ ਪੇ ਕਰੋ',
          'payAtCounter': 'ਕਾਊਂਟਰ ਤੇ ਪੇ ਕਰੋ',
          'pos': 'POS',
          'posOrder': 'POS ਆਰਡਰ',
          'onlineOrder': 'ਆਨਲਾਈਨ ਆਰਡਰ',
          'customerIsHere': 'ਗਾਹਕ ਇੱਥੇ ਹੈ',
          'new': 'ਨਵਾਂ',
          'order': 'ਆਰਡਰ',
          'items': 'ਆਈਟਮਾਂ',
          'customer': 'ਗਾਹਕ',
          'phone': 'ਫ਼ੋਨ',
          'status': 'ਸਟੇਟਸ',
          'paymentMethod': 'ਪੇਮੈਂਟ ਤਰੀਕਾ',
          'paymentStatus': 'ਪੇਮੈਂਟ ਸਟੇਟਸ',
          'skipLine': 'ਲਾਈਨ ਛੱਡੋ',
          'customerHere': 'ਗਾਹਕ ਇੱਥੇ ਹੈ',
          'arrivedAt': 'ਆਇਆ ਸਮਾਂ',
          'distance': 'ਦੂਰੀ',
          'customerLocationReceived': 'ਗਾਹਕ ਦੀ ਲੋਕੇਸ਼ਨ ਮਿਲੀ',
          'viewMap': 'ਮੈਪ ਵੇਖੋ',
          'total': 'ਕੁੱਲ',
          'cashReceived': 'ਕੈਸ਼ ਮਿਲਿਆ',
          'changeDue': 'ਚੇਂਜ ਬਾਕੀ',
          'transaction': 'ਲੈਣ-ਦੇਣ',
          'completeWord': 'ਪੂਰਾ',
          'accept': 'ਸਵੀਕਾਰ',
          'reject': 'ਰਿਜੈਕਟ',
          'complete': 'ਪੂਰਾ ਕਰੋ',
          'paymentOptions': 'ਪੇਮੈਂਟ ਵਿਕਲਪ',
          'paymentReceived': 'ਪੇਮੈਂਟ ਮਿਲੀ',
          'share': 'ਸ਼ੇਅਰ',
          'call': 'ਕਾਲ',
          'returning': 'ਵਾਪਸ ਆਇਆ',
          'visits': 'ਵਿਜ਼ਿਟ',
          'newCustomer': 'ਨਵਾਂ ਗਾਹਕ',
          'reward': 'ਰਿਵਾਰਡ',
          'noItems': 'ਕੋਈ ਆਈਟਮ ਨਹੀਂ',
          'notSelected': 'ਚੁਣਿਆ ਨਹੀਂ',
          'unpaid': 'ਪੇਮੈਂਟ ਬਾਕੀ',
          'paid': 'ਪੇਮੈਂਟ ਹੋ ਗਈ',
          'waitingApproval': 'ਓਨਰ ਅਪ੍ਰੂਵਲ ਦੀ ਉਡੀਕ',
          'waitingPaymentOptions': 'ਪੇਮੈਂਟ ਵਿਕਲਪ ਭੇਜਣ ਦੀ ਉਡੀਕ',
          'readOrder': 'ਆਰਡਰ ਸੁਣੋ',
        }[key] ?? key;
      default:
        return {
          'orders': 'Orders',
          'orderWord': 'orders',
          'today': 'Today',
          'week': 'Week',
          'month': 'Month',
          'year': 'Year',
          'showFilters': 'Show Filters',
          'hideFilters': 'Hide Filters',
          'searchOrders': 'Search orders',
          'dateRange': 'Date Range',
          'clearDateRange': 'Clear Date Range',
          'noOrdersFound': 'No orders found',
          'all': 'All',
          'pending': 'Pending',
          'accepted': 'Accepted',
          'preparing': 'Preparing',
          'ready': 'Ready',
          'completed': 'Completed',
          'rejected': 'Rejected',
          'payNow': 'Pay Now',
          'payAtCounter': 'Pay at Counter',
          'pos': 'POS',
          'posOrder': 'POS Order',
          'onlineOrder': 'Online Order',
          'customerIsHere': 'CUSTOMER IS HERE',
          'new': 'NEW',
          'order': 'Order',
          'items': 'Items',
          'customer': 'Customer',
          'phone': 'Phone',
          'status': 'Status',
          'paymentMethod': 'Payment Method',
          'paymentStatus': 'Payment Status',
          'skipLine': 'Skip the Line',
          'customerHere': 'Customer is here',
          'arrivedAt': 'Arrived At',
          'distance': 'Distance',
          'customerLocationReceived': 'Customer location received',
          'viewMap': 'View Map',
          'total': 'Total',
          'cashReceived': 'Cash Received',
          'changeDue': 'Change Due',
          'transaction': 'Transaction',
          'completeWord': 'Complete',
          'accept': 'Accept',
          'reject': 'Reject',
          'complete': 'Complete',
          'paymentOptions': 'Payment Options',
          'paymentReceived': 'Payment Received',
          'share': 'Share',
          'call': 'Call',
          'returning': 'Returning',
          'visits': 'visits',
          'newCustomer': 'New Customer',
          'reward': 'Reward',
          'noItems': 'No items',
          'notSelected': 'Not selected',
          'unpaid': 'Unpaid',
          'paid': 'Paid',
          'waitingApproval': 'Waiting for owner approval',
          'waitingPaymentOptions': 'Waiting to send payment options',
          'readOrder': 'Read order',
        }[key] ?? key;
    }
  }

  String _displayStatusText(String status) {
    switch (status.trim().toLowerCase()) {
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
      case 'rejected':
        return _txt('rejected');
      default:
        return status;
    }
  }

  String _displayPaymentText(String status) {
    final clean = status.trim();
    switch (clean.toLowerCase()) {
      case 'paid':
        return _txt('paid');
      case 'unpaid':
        return _txt('unpaid');
      case 'not selected':
        return _txt('notSelected');
      case 'pay at counter':
        return _txt('payAtCounter');
      case 'waiting for owner approval':
        return _txt('waitingApproval');
      case 'waiting to send payment options':
        return _txt('waitingPaymentOptions');
      case 'payment request sent':
      case 'payment sent':
        return _txt('paymentOptions');
      default:
        return clean;
    }
  }

  Future<void> _setupOrdersVoice() async {
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

  Future<void> _toggleSpeakOrder(String orderId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    await _setupOrdersVoice();

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

  String _buildOwnerOrderSpeech({
    required int index,
    required String business,
    required String customer,
    required String items,
    required String total,
    required String status,
    required String paymentMethod,
    required String paymentStatus,
  }) {
    final orderNumber = index + 1;
    final safeBusiness = business.trim().isEmpty ? _txt('orders') : business;
    final safeCustomer = customer.trim().isEmpty ? 'N/A' : customer;

    switch (AppText.language) {
      case 'es':
        return 'Pedido número $orderNumber de $safeBusiness. Cliente: $safeCustomer. Estado: ${_displayStatusText(status)}. Artículos: $items. Total: $total dólares. Pago: $paymentStatus. Método: $paymentMethod.';
      case 'hi':
        return 'ऑर्डर नंबर $orderNumber, $safeBusiness से। ग्राहक: $safeCustomer। स्टेटस: ${_displayStatusText(status)}। आइटम: $items। कुल: $total डॉलर। पेमेंट: $paymentStatus। तरीका: $paymentMethod।';
      case 'pa':
        return 'ਆਰਡਰ ਨੰਬਰ $orderNumber, $safeBusiness ਤੋਂ। ਗਾਹਕ: $safeCustomer। ਸਟੇਟਸ: ${_displayStatusText(status)}। ਆਈਟਮਾਂ: $items। ਕੁੱਲ: $total ਡਾਲਰ। ਪੇਮੈਂਟ: $paymentStatus। ਤਰੀਕਾ: $paymentMethod।';
      default:
        return 'Order number $orderNumber from $safeBusiness. Customer: $safeCustomer. Status: $status. Items: $items. Total: $total dollars. Payment: $paymentStatus. Method: $paymentMethod.';
    }
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
  Future<void> _sendCustomerSms(String phone, String message) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    final Uri uri = Uri.parse(
      'sms:$cleanPhone?body=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS not supported on this device')),
      );
    }
  }
  Future<void> _sendCustomerWhatsApp(String phone, String message) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length == 10) {
      cleanPhone = '1$cleanPhone';
    }

    final Uri appUri = Uri.parse(
      'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
    );

    final Uri webUri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
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
  Future<void> _showArrivalMapDialog(Map<String, dynamic> order) async {
    final double? lat = double.tryParse(
      (order['customerLatitude'] ?? '').toString(),
    );
    final double? lng = double.tryParse(
      (order['customerLongitude'] ?? '').toString(),
    );

    if (lat == null || lng == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Customer Location'),
          content: SizedBox(
            width: double.maxFinite,
            height: 260,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openArrivalDirections(latitude: lat, longitude: lng);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Open Maps'),
            ),
          ],
        );
      },
    );
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
        label: Text(label == 'All' ? _txt('all') : _displayStatusText(label)),
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
        label: Text(
          type == 'All'
              ? _txt('all')
              : type == 'Pay Now'
                  ? _txt('payNow')
                  : type == 'Pay at Counter'
                      ? _txt('payAtCounter')
                      : _txt('pos'),
        ),
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
      appBar: AppBar(title: Text(_txt('orders'))),
      body: Column(
        children: [
          const SizedBox(height: 8),

          AnimatedSwitcher(
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return currentChild ?? const SizedBox.shrink();
            },
            duration: const Duration(milliseconds: 250),
            child: _showStats
                ? Padding(
              key: const ValueKey('stats-visible'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactStat(
                      title: _txt('today'),
                      value: '${todayStats['count']} ${_txt('orderWord')}',
                      subValue: '\$${todayStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: _txt('week'),
                      value: '${weekStats['count']} ${_txt('orderWord')}',
                      subValue: '\$${weekStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.calendar_view_week,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: _txt('month'),
                      value: '${monthStats['count']} ${_txt('orderWord')}',
                      subValue: '\$${monthStats['sales'].toStringAsFixed(2)}',
                      icon: Icons.calendar_month,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStat(
                      title: _txt('year'),
                      value: '${yearStats['count']} ${_txt('orderWord')}',
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
                    label: Text(_showFilters ? _txt('hideFilters') : _txt('showFilters')),
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
                    key: const ValueKey('orders_search_field'),
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: _txt('searchOrders'),
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
                  tooltip: _txt('dateRange'),
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    tooltip: _txt('clearDateRange'),
                    onPressed: _clearDateRange,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filteredIndices.isEmpty
                ? Center(
              child: Text(
                _txt('noOrdersFound'),
                style: const TextStyle(fontSize: 16),
              ),
            )
                :ListView.builder(
              controller: _ordersScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredIndices.length,
              itemBuilder: (context, filteredIndex) {
                final int index = filteredIndices[filteredIndex];
                final order = orders[index];
                final String phone = (order['phone'] ?? '').toString();

                final bool isReturningCustomer = phone.trim().isNotEmpty &&
                    OrderData.orders.where((o) {
                      return (o['phone'] ?? '').toString().trim() == phone.trim();
                    }).length > 1;

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _txt('readOrder'),
                              onPressed: () => _toggleSpeakOrder(
                                'owner_order_$index',
                                _buildOwnerOrderSpeech(
                                  index: index,
                                  business: business,
                                  customer: customer,
                                  items: items,
                                  total: total,
                                  status: status,
                                  paymentMethod: paymentMethod,
                                  paymentStatus: _displayPaymentText(paymentStatus),
                                ),
                              ),
                              icon: const Icon(Icons.volume_up, color: Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              isPosOrder
                                  ? _txt('posOrder')
                                  : isHereNow
                                  ? _txt('customerIsHere')
                                  : _txt('onlineOrder'),
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
                                child: Text(
                                  _txt('new'),
                                  style: const TextStyle(
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
                          _txt('order'),
                          '#${index + 1} • ${_formatOrderDateTime(order, index)}',
                          valueColor: Colors.grey.shade800,
                          valueWeight: FontWeight.w600,
                        ),
                        _infoLine(_txt('items'), items),
                        Row(
                          children: [
                            Expanded(
                              child: _infoLine(
                                _txt('customer'),
                                customer.isEmpty ? 'N/A' : customer,
                              ),
                            ),
                            if (phone.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isReturningCustomer
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final int visits =
                                    (order['visitCount'] is num)
                                        ? (order['visitCount'] as num).toInt()
                                        : 1;

                                    final int punches =
                                    (order['rewardPunches'] is num)
                                        ? (order['rewardPunches'] as num).toInt()
                                        : 1;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isReturningCustomer
                                              ? '${_txt('returning')} • $visits ${_txt('visits')}'
                                              : _txt('newCustomer'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isReturningCustomer
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                        ),

                                        if (isReturningCustomer)
                                          Text(
                                            '${_txt('reward')} $punches/5',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        _infoLine(_txt('phone'), phone.isEmpty ? 'N/A' : phone),
                        _infoLine(
                          _txt('status'),
                          _displayStatusText(status),
                          valueColor: isRejected
                              ? Colors.red
                              : isCompleted
                              ? Colors.green
                              : Colors.black87,
                        ),
                        _infoLine(
                          _txt('paymentMethod'),
                          paymentMethod,
                          valueColor: Colors.indigo,
                        ),
                        _infoLine(
                          _txt('paymentStatus'),
                          _displayPaymentText(paymentStatus),
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
                            _txt('skipLine'),
                            _txt('customerHere'),
                            valueColor: Colors.green,
                            valueWeight: FontWeight.bold,
                          ),
                        if ((order['arrivedAt'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty)
                          _infoLine(
                            _txt('arrivedAt'),
                            (order['arrivedAt'] ?? '').toString(),
                            valueColor: Colors.green,
                            valueWeight: FontWeight.w600,
                          ),
                        if (order['arrivalDistanceMeters'] != null)
                          _infoLine(
                            _txt('distance'),
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
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.green),
                                const SizedBox(width: 10),
                                 Expanded(
                                  child: Text(
                                    _txt('customerLocationReceived'),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showArrivalMapDialog(order),
                                  icon: const Icon(Icons.map),
                                  label: Text(_txt('viewMap')),
                                ),
                              ],
                            ),
                          ),
                        if (total.trim().isNotEmpty)
                          _infoLine(
                            _txt('total'),
                            '\$$total',
                            valueWeight: FontWeight.bold,
                          ),
                        if ((order['cashReceived'] ?? '').toString().trim().isNotEmpty)
                          _infoLine(
                            _txt('cashReceived'),
                            '\$${order['cashReceived']}',
                            valueColor: Colors.green,
                            valueWeight: FontWeight.w600,
                          ),

                        if ((order['changeDue'] ?? '').toString().trim().isNotEmpty)
                          _infoLine(
                            _txt('changeDue'),
                            '\$${order['changeDue']}',
                            valueColor: Colors.orange,
                            valueWeight: FontWeight.w600,
                          ),
                        if (transactionComplete)
                          _infoLine(
                            _txt('transaction'),
                            _txt('completeWord'),
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
                              child: Text(_txt('accept')),
                            ),
                            ElevatedButton(
                              onPressed: status == 'Pending'
                                  ? () => _rejectOrder(index)
                                  : null,
                              child: Text(_txt('reject')),
                            ),
                            ElevatedButton(
                              onPressed: canStartPreparing
                                  ? () => _updateStatus(index, 'Preparing')
                                  : null,
                              child: Text(_txt('preparing')),
                            ),
                            ElevatedButton(
                              onPressed: isPreparing
                                  ? () => _updateStatus(index, 'Ready')
                                  : null,
                              child: Text(_txt('ready')),
                            ),
                            ElevatedButton(
                              onPressed: isReady
                                  ? () => _updateStatus(index, 'Completed')
                                  : null,
                              child: Text(_txt('complete')),
                            ),
                            if (showSendPaymentOptions)
                              OutlinedButton(
                                onPressed: () =>
                                    _showPaymentOptionsDialog(index),
                                child: Text(_txt('paymentOptions')),
                              ),
                            if (showPaymentReceived)
                              OutlinedButton(
                                onPressed: () =>
                                    _markPaymentReceived(index),
                                child: Text(_txt('paymentReceived')),
                              ),
                              if (isCompleted)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await _printPosReceipt(order);
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('Reprint Receipt'),
                                ),
                            if (phone.trim().isNotEmpty) ...[
                              OutlinedButton.icon(
                                onPressed: () {
                                  final message =
                                      'Hi $customer! Your order is ready.\n\n'
                                      'Skip the line next time using MapMyBite:\n'
                                      'https://mapmybite.app';

                                  Share.share(message);
                                },
                                icon: const Icon(Icons.share),
                                label: Text(_txt('share')),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

                                  if (cleanPhone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No phone number saved')),
                                    );
                                    return;
                                  }

                                  final Uri uri = Uri.parse('tel:$cleanPhone');

                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Call not supported on this device')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.call),
                                label: Text(_txt('call')),
                              ),
                            ],
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