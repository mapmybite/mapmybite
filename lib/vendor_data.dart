import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorData {
  static const String _storageKey = 'mapmybite_vendors';

  static List<Map<String, dynamic>> vendors = [
    {
      'id': 'truck_1',
      'title': 'Tasty Truck',
      'cuisine': 'Mexican Food',
      'isVerified': true,
      'plan': 'pro',
      'position': const LatLng(37.9577, -121.2908),
      'latitude': 37.9577,
      'longitude': -121.2908,
      'type': 'truck',
      'phone': '(209) 111-1111',
      'timing': '10:00 AM - 8:00 PM',
      'menu': 'Tacos, Burritos, Quesadillas',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Fresh Mexican street food in Stockton.',
      'image': 'assets/images/mexican_food.jpg',
      'galleryImages': [
        'assets/images/mexican_food.jpg',
        'assets/images/fast_food.jpg',
        'assets/images/indian_food.jpg',
        'assets/images/punjabi_food.jpg',
      ],
      'dailySpecial': 'Buy 2 tacos get 1 free today only',
    },
    {
      'id': 'truck_2',
      'title': 'Street Bites',
      'cuisine': 'Fast Food',
      'isVerified': true,
      'plan': 'premium',
      'position': const LatLng(37.9650, -121.3000),
      'latitude': 37.9650,
      'longitude': -121.3000,
      'type': 'truck',
      'phone': '(209) 222-2222',
      'timing': '11:00 AM - 9:00 PM',
      'menu': 'Burgers, Fries, Wraps',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Quick and tasty fast food favorites.',
      'image': 'assets/images/fast_food.jpg',
      'galleryImages': [
        'assets/images/fast_food.jpg',
        'assets/images/mexican_food.jpg',
        'assets/images/indian_food.jpg',
        'assets/images/punjabi_food.jpg',
      ],
      'dailySpecial': 'Free drink with any combo meal',
    },
    {
      'id': 'truck_3',
      'title': 'Curry Stop',
      'cuisine': 'Indian Food',
      'isVerified': true,
      'plan': 'platinum',
      'position': const LatLng(37.9500, -121.2800),
      'latitude': 37.9500,
      'longitude': -121.2800,
      'type': 'truck',
      'phone': '(209) 333-3333',
      'timing': '12:00 PM - 10:00 PM',
      'menu': 'Butter Chicken, Naan, Samosa',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Flavorful Indian food on the go.',
      'image': 'assets/images/indian_food.jpg',
      'galleryImages': [
        'assets/images/indian_food.jpg',
        'assets/images/mexican_food.jpg',
        'assets/images/fast_food.jpg',
        'assets/images/punjabi_food.jpg',
      ],
      'dailySpecial': 'Today special thali available until 4 PM',
    },
    {
      'id': 'truck_4',
      'title': "Mannat's Food Truck",
      'cuisine': 'Punjabi Food',
      'isVerified': true,
      'plan': 'pro',
      'position': const LatLng(37.9545, -121.2750),
      'latitude': 37.9545,
      'longitude': -121.2750,
      'type': 'truck',
      'phone': '(209) 444-4444',
      'timing': '9:00 AM - 7:00 PM',
      'menu': 'Chole Bhature, Paneer Wrap, Lassi',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Punjabi comfort food with a fun twist.',
      'image': 'assets/images/punjabi_food.jpg',
      'galleryImages': [
        'assets/images/punjabi_food.jpg',
        'assets/images/indian_food.jpg',
        'assets/images/mexican_food.jpg',
        'assets/images/fast_food.jpg',
      ],
      'dailySpecial': 'Paneer wrap combo discount today',
    },
    {
      'id': 'kitchen_1',
      'title': 'Maa Da Swad Kitchen',
      'cuisine': 'Punjabi Home Food',
      'isVerified': true,
      'plan': 'free',
      'position': const LatLng(37.9700, -121.3100),
      'latitude': 37.9700,
      'longitude': -121.3100,
      'type': 'kitchen',
      'phone': '(209) 555-1111',
      'timing': '8:00 AM - 6:00 PM',
      'menu': 'Paratha, Dal, Sabzi',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Homestyle Punjabi meals made fresh daily.',
      'image': 'assets/images/home_food.jpg',
      'galleryImages': [
        'assets/images/home_food.jpg',
        'assets/images/punjabi_food.jpg',
        'assets/images/indian_food.jpg',
        'assets/images/mexican_food.jpg',
      ],
      'dailySpecial': 'Fresh paratha breakfast special before 11 AM',
    },
    {
      'id': 'kitchen_2',
      'title': 'Taste of Home Kitchen',
      'cuisine': 'Indian Vegetarian',
      'isVerified': true,
      'plan': 'platinum',
      'position': const LatLng(37.9450, -121.2950),
      'latitude': 37.9450,
      'longitude': -121.2950,
      'type': 'kitchen',
      'phone': '(209) 555-2222',
      'timing': '9:00 AM - 5:00 PM',
      'menu': 'Rajma Rice, Aloo Gobi, Roti',
      'menuItems': [],
      'cashApp': '',
      'zelle': '',
      'venmo': '',
      'description': 'Fresh vegetarian home kitchen meals.',
      'image': 'assets/images/home_food.jpg',
      'galleryImages': [
        'assets/images/home_food.jpg',
        'assets/images/indian_food.jpg',
        'assets/images/punjabi_food.jpg',
        'assets/images/fast_food.jpg',
      ],
      'dailySpecial': 'chole bhature breakfast special before 11 AM',
    },
  ];

  static List<Map<String, dynamic>> get allVendors => vendors;

  static List<Map<String, dynamic>> get foodTrucks =>
      vendors.where((vendor) => vendor['type'] == 'truck').toList();

  static List<Map<String, dynamic>> get homeKitchens =>
      vendors.where((vendor) {
        final type = vendor['type']?.toString();
        return type == 'kitchen' || type == 'home_kitchen';
      }).toList();

  static Future<void> loadVendors() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return;
    }

    vendors = decoded.map<Map<String, dynamic>>((item) {
      final map = Map<String, dynamic>.from(item as Map);

      final latitude = (map['latitude'] is num)
          ? (map['latitude'] as num).toDouble()
          : double.tryParse(map['latitude']?.toString() ?? '') ?? 37.9577;

      final longitude = (map['longitude'] is num)
          ? (map['longitude'] as num).toDouble()
          : double.tryParse(map['longitude']?.toString() ?? '') ?? -121.2908;

      map['latitude'] = latitude;
      map['longitude'] = longitude;
      map['position'] = LatLng(latitude, longitude);

      return map;
    }).toList();
  }

  static Future<void> saveVendors() async {
    final prefs = await SharedPreferences.getInstance();

    final saveList = vendors.map((vendor) {
      final map = Map<String, dynamic>.from(vendor);

      if (map['position'] is LatLng) {
        final position = map['position'] as LatLng;
        map['latitude'] = position.latitude;
        map['longitude'] = position.longitude;
      }

      map.remove('position');

      return map;
    }).toList();

    await prefs.setString(_storageKey, jsonEncode(saveList));
  }

  static Future<void> addOrUpdateVendor(Map<String, dynamic> vendor) async {
    final id = vendor['id']?.toString() ?? '';

    if (id.isEmpty) {
      return;
    }

    if (vendor['position'] is LatLng) {
      final position = vendor['position'] as LatLng;
      vendor['latitude'] = position.latitude;
      vendor['longitude'] = position.longitude;
    } else {
      final latitude = (vendor['latitude'] is num)
          ? (vendor['latitude'] as num).toDouble()
          : double.tryParse(vendor['latitude']?.toString() ?? '') ?? 37.9577;

      final longitude = (vendor['longitude'] is num)
          ? (vendor['longitude'] as num).toDouble()
          : double.tryParse(vendor['longitude']?.toString() ?? '') ?? -121.2908;

      vendor['latitude'] = latitude;
      vendor['longitude'] = longitude;
      vendor['position'] = LatLng(latitude, longitude);
    }

    final index = vendors.indexWhere(
      (item) => item['id']?.toString() == id,
    );

    if (index == -1) {
      vendors.add(Map<String, dynamic>.from(vendor));
    } else {
      vendors[index] = {
        ...vendors[index],
        ...vendor,
      };
    }

    await saveVendors();
  }

  static Future<void> deleteVendor(String id) async {
    vendors.removeWhere((item) => item['id']?.toString() == id);
    await saveVendors();
  }
}