class OwnerCustomerData {
  static final List<Map<String, dynamic>> customers = [];

  static Map<String, dynamic>? saveOrUpdateCustomer({
    required String business,
    required String name,
    required String phone,
    required double totalSpent,
  }) {
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
      return customers.last;
    } else {
      customers[index]['name'] = cleanName;
      customers[index]['visitCount'] =
          ((customers[index]['visitCount'] ?? 0) as int) + 1;
      customers[index]['totalSpent'] =
          ((customers[index]['totalSpent'] ?? 0.0) as num).toDouble() +
              totalSpent;
      customers[index]['rewardPunches'] =
          ((customers[index]['rewardPunches'] ?? 0) as int) + 1;
      customers[index]['lastVisit'] = DateTime.now().toIso8601String();
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