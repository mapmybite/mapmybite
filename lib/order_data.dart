import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OrderData {
  static const String _ordersKey = 'mapmybite_orders';
  static const String _notificationsKey = 'mapmybite_order_notifications';

  static List<Map<String, dynamic>> orders = [];
  static List<Map<String, dynamic>> notifications = [];

  static Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();

    final rawOrders = prefs.getString(_ordersKey);
    if (rawOrders != null && rawOrders.isNotEmpty) {
      final decodedOrders = jsonDecode(rawOrders);
      if (decodedOrders is List) {
        orders = decodedOrders
            .whereType<Map>()
            .map((item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList();
      }
    }

    final rawNotifications = prefs.getString(_notificationsKey);
    if (rawNotifications != null && rawNotifications.isNotEmpty) {
      final decodedNotifications = jsonDecode(rawNotifications);
      if (decodedNotifications is List) {
        notifications = decodedNotifications
            .whereType<Map>()
            .map((item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList();
      }
    }
  }

  static Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_ordersKey, jsonEncode(orders));
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  static Future<void> addOrder(Map<String, dynamic> order) async {
    orders.add(order);
    await saveOrders();
  }

  static Future<void> updateOrder(int index, Map<String, dynamic> updatedOrder) async {
    if (index < 0 || index >= orders.length) return;

    orders[index] = {
      ...orders[index],
      ...updatedOrder,
    };

    await saveOrders();
  }

  static Future<void> addNotification({
    required String audience,
    required String title,
    required String message,
    String business = '',
    String customer = '',
    String type = 'general',
  }) async {
    notifications.insert(0, {
      'audience': audience,
      'title': title,
      'message': message,
      'business': business,
      'customer': customer,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });

    await saveOrders();
  }

  static Future<void> markCustomerArrived({
    required int index,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required String arrivedAt,
  }) async {
    if (index < 0 || index >= orders.length) return;

    orders[index]['customerAtLocation'] = true;
    orders[index]['customerLatitude'] = latitude;
    orders[index]['customerLongitude'] = longitude;
    orders[index]['arrivalDistanceMeters'] = distanceMeters;
    orders[index]['arrivedAt'] = arrivedAt;
    orders[index]['skipLine'] = true;

    await addNotification(
      audience: 'owner',
      title: 'Customer Arrived',
      message: '${orders[index]['customer'] ?? 'Customer'} is here for pickup.',
      business: (orders[index]['business'] ?? '').toString(),
      customer: (orders[index]['customer'] ?? '').toString(),
      type: 'arrival',
    );

    await saveOrders();
  }

  static List<Map<String, dynamic>> getCustomerOrders() {
    final filtered = List<Map<String, dynamic>>.from(orders);

    filtered.sort((a, b) {
      final DateTime aTime = _parseDateTime(
        a['createdAt'] ??
            a['orderedAt'] ??
            a['placedAt'] ??
            a['dateTime'] ??
            a['timestamp'] ??
            a['date'],
      );
      final DateTime bTime = _parseDateTime(
        b['createdAt'] ??
            b['orderedAt'] ??
            b['placedAt'] ??
            b['dateTime'] ??
            b['timestamp'] ??
            b['date'],
      );
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    final text = value.toString().trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    return DateTime.tryParse(text) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}