import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OwnerCustomerData {
  static const String _storageKey = 'mapmybite_owner_customers';

  static List<Map<String, dynamic>> customers = [];

  static Future<void> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);

    if (decoded is List) {
      customers = decoded
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
  }

  static Future<void> saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(customers));
  }

  static Future<Map<String, dynamic>?> saveOrUpdateCustomer({
    required String business,
    required String name,
    required String phone,
    required double totalSpent,
  }) async {
    final cleanPhone = phone.trim();
    final cleanName = name.trim().isEmpty ? 'Walk-in Customer' : name.trim();

    if (cleanPhone.isEmpty) return null;

    final index = customers.indexWhere(
      (customer) =>
          customer['business'] == business &&
          customer['phone'] == cleanPhone,
    );

    if (index == -1) {
      customers.add({
        'business': business,
        'name': cleanName,
        'phone': cleanPhone,
        'visitCount': 1,
        'totalSpent': totalSpent,
        'rewardPunches': 1,
        'lastVisit': DateTime.now().toIso8601String(),
      });

      await saveCustomers();
      return customers.last;
    } else {
      customers[index]['name'] = cleanName;
      customers[index]['visitCount'] =
          ((customers[index]['visitCount'] ?? 0) as num).toInt() + 1;
      customers[index]['totalSpent'] =
          ((customers[index]['totalSpent'] ?? 0.0) as num).toDouble() +
              totalSpent;
      customers[index]['rewardPunches'] =
          ((customers[index]['rewardPunches'] ?? 0) as num).toInt() + 1;
      customers[index]['lastVisit'] = DateTime.now().toIso8601String();

      await saveCustomers();
      return customers[index];
    }
  }

  static List<Map<String, dynamic>> customersForBusiness(String business) {
    return customers
        .where((customer) => customer['business'] == business)
        .toList();
  }

  static Map<String, dynamic>? findCustomer({
    required String business,
    required String phone,
  }) {
    final cleanPhone = phone.trim();

    try {
      return customers.firstWhere(
        (customer) =>
            customer['business'] == business &&
            customer['phone'] == cleanPhone,
      );
    } catch (_) {
      return null;
    }
  }
}