class OrderData {
  static List<Map<String, dynamic>> orders = [];
  static List<Map<String, dynamic>> notifications = [];

  static void addNotification({
    required String audience,
    required String title,
    required String message,
    String business = '',
    String customer = '',
    String type = 'general',
  }) {
    notifications.insert(0, {
      'audience': audience, // customer / owner / all
      'title': title,
      'message': message,
      'business': business,
      'customer': customer,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  static void markCustomerArrived({
    required int index,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required String arrivedAt,
  }) {
    if (index < 0 || index >= orders.length) return;

    orders[index]['customerAtLocation'] = true;
    orders[index]['customerLatitude'] = latitude;
    orders[index]['customerLongitude'] = longitude;
    orders[index]['arrivalDistanceMeters'] = distanceMeters;
    orders[index]['arrivedAt'] = arrivedAt;
    orders[index]['skipLine'] = true;

    addNotification(
      audience: 'owner',
      title: 'Customer Arrived',
      message: '${orders[index]['customer'] ?? 'Customer'} is here for pickup.',
      business: (orders[index]['business'] ?? '').toString(),
      customer: (orders[index]['customer'] ?? '').toString(),
      type: 'arrival',
    );
  }
}