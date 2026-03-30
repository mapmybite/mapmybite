import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'owner_portal_page.dart';
import 'truck_profile_page.dart';
import 'orders_page.dart';

class TruckPage extends StatefulWidget {
  const TruckPage({super.key});

  @override
  State<TruckPage> createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  GoogleMapController? mapController;

  BitmapDescriptor? truckIcon;
  BitmapDescriptor? homeKitchenIcon;
  bool iconsLoaded = false;
  bool _isOpeningProfile = false;

  final LatLng _initialPosition = const LatLng(37.9577, -121.2908);

  final List<Map<String, dynamic>> foodTrucks = [
    {
      'id': 'truck_1',
      'title': 'Tasty Truck',
      'cuisine': 'Mexican Food',
      'position': const LatLng(37.9577, -121.2908),
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
      'position': const LatLng(37.9650, -121.3000),
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
      'position': const LatLng(37.9500, -121.2800),
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
      'title': 'Mannat\'s Food Truck',
      'cuisine': 'Punjabi Food',
      'position': const LatLng(37.9545, -121.2750),
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
  ];

  final List<Map<String, dynamic>> homeKitchens = [
    {
      'id': 'kitchen_1',
      'title': 'Maa Da Swad Kitchen',
      'cuisine': 'Punjabi Home Food',
      'position': const LatLng(37.9700, -121.3100),
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
      'position': const LatLng(37.9450, -121.2950),
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

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      final truckBytes = await rootBundle.load('assets/images/food_truck.png');
      final truckCodec = await ui.instantiateImageCodec(
        truckBytes.buffer.asUint8List(),
        targetWidth: 95,
      );
      final truckFrame = await truckCodec.getNextFrame();
      final truckData =
      await truckFrame.image.toByteData(format: ui.ImageByteFormat.png);

      final kitchenBytes =
      await rootBundle.load('assets/images/home_kitchen.png');
      final kitchenCodec = await ui.instantiateImageCodec(
        kitchenBytes.buffer.asUint8List(),
        targetWidth: 95,
      );
      final kitchenFrame = await kitchenCodec.getNextFrame();
      final kitchenData =
      await kitchenFrame.image.toByteData(format: ui.ImageByteFormat.png);

      setState(() {
        truckIcon = BitmapDescriptor.fromBytes(
          truckData!.buffer.asUint8List(),
        );
        homeKitchenIcon = BitmapDescriptor.fromBytes(
          kitchenData!.buffer.asUint8List(),
        );
        iconsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading icons: $e');
      setState(() {
        iconsLoaded = true;
      });
    }
  }

  void _openProfilePage(Map<String, dynamic> item) {
    if (_isOpeningProfile) return;

    _isOpeningProfile = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckProfilePage(truck: item),
      ),
    ).then((_) {
      _isOpeningProfile = false;
    });
  }

  Future<void> _openOwnerPortal() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerPortalPage(),
      ),
    );

    if (result == null) return;

    final bool isFoodTruck = result['type'] == 'food_truck';

    final Map<String, dynamic> newBusiness = {
      'id': result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': result['title'] ?? '',
      'cuisine': result['cuisine'] ?? '',
      'position': _generateNewBusinessPosition(isFoodTruck),
      'type': isFoodTruck ? 'truck' : 'kitchen',
      'phone': result['phone'] ?? '',
      'timing': _buildTimingFromResult(result),
      'openTime': result['openTime'] ?? '',
      'closeTime': result['closeTime'] ?? '',
      'address': result['address'] ?? '',
      'menu': result['menu'] ?? '',
      'menuItems': result['menuItems'] ?? [],
      'description': result['description'] ?? '',
      'image': result['bannerImage'] ?? _pickMainImage(result),
      'bannerImage': result['bannerImage'] ?? '',
      'galleryImages': _normalizeGalleryImages(result['galleryImages']),
      'storyVideos': _normalizeStoryVideos(result['storyVideos']),
      'storyVideo': result['storyVideo'] ?? '',
      'storyCreatedAt': result['storyCreatedAt'] ?? '',
      'instagram': result['instagram'] ?? '',
      'facebook': result['facebook'] ?? '',
      'tiktok': result['tiktok'] ?? '',
      'youtube': result['youtube'] ?? '',
      'whatsapp': result['whatsapp'] ?? '',
      'cashApp': result['cashApp'] ?? '',
      'zelle': result['zelle'] ?? '',
      'venmo': result['venmo'] ?? '',
      'dailySpecial': 'New business added on MapMyBite',
    };

    setState(() {
      if (isFoodTruck) {
        foodTrucks.add(newBusiness);
      } else {
        homeKitchens.add(newBusiness);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFoodTruck
              ? 'Food truck added successfully'
              : 'Home kitchen added successfully',
        ),
      ),
    );

    _openProfilePage(newBusiness);
  }

  LatLng _generateNewBusinessPosition(bool isFoodTruck) {
    final int count = isFoodTruck ? foodTrucks.length : homeKitchens.length;
    final double latOffset = 0.004 + (count * 0.0015);
    final double lngOffset = 0.004 + (count * 0.0012);

    return LatLng(
      _initialPosition.latitude + latOffset,
      _initialPosition.longitude + lngOffset,
    );
  }

  String _buildTimingFromResult(Map<String, dynamic> result) {
    final String openTime = (result['openTime'] ?? '').toString().trim();
    final String closeTime = (result['closeTime'] ?? '').toString().trim();

    if (openTime.isNotEmpty && closeTime.isNotEmpty) {
      return '$openTime - $closeTime';
    }

    if (openTime.isNotEmpty) return openTime;
    if (closeTime.isNotEmpty) return closeTime;

    return 'Timing not available';
  }

  List<String> _normalizeGalleryImages(dynamic gallery) {
    if (gallery is List) {
      return gallery
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _normalizeStoryVideos(dynamic stories) {
    if (stories is List) {
      return stories
          .whereType<Map>()
          .map(
            (story) => {
          'path': (story['path'] ?? '').toString(),
          'createdAt': (story['createdAt'] ?? '').toString(),
          'label': (story['label'] ?? 'Story').toString(),
        },
      )
          .where((story) => (story['path'] ?? '').toString().isNotEmpty)
          .toList();
    }
    return [];
  }

  String _pickMainImage(Map<String, dynamic> result) {
    final List<String> gallery = _normalizeGalleryImages(result['galleryImages']);
    if (gallery.isNotEmpty) return gallery.first;
    return '';
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    for (final truck in foodTrucks) {
      markers.add(
        Marker(
          markerId: MarkerId(truck['id']),
          position: truck['position'],
          icon: truckIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: truck['title']),
          onTap: () {
            _openProfilePage(truck);
          },
        ),
      );
    }

    for (final kitchen in homeKitchens) {
      markers.add(
        Marker(
          markerId: MarkerId(kitchen['id']),
          position: kitchen['position'],
          icon: homeKitchenIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
          infoWindow: InfoWindow(title: kitchen['title']),
          onTap: () {
            _openProfilePage(kitchen);
          },
        ),
      );
    }

    return markers;
  }

  void _showBusinessList(String title, List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${items.length} total',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: item['type'] == 'truck'
                                ? Colors.orange.shade100
                                : Colors.purple.shade100,
                            child: Icon(
                              item['type'] == 'truck'
                                  ? Icons.local_shipping
                                  : Icons.home_work,
                              color: item['type'] == 'truck'
                                  ? Colors.orange
                                  : Colors.purple,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${item['cuisine']}\n${item['timing']}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing:
                          const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _openProfilePage(item);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToMapHome() {
    Navigator.pop(context);
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MapMyBite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'MapMyBite Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: _goToMapHome,
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(
                'Map (${foodTrucks.length} trucks, ${homeKitchens.length} kitchens)',
              ),
              onTap: _goToMapHome,
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Food Trucks'),
              subtitle: Text('${foodTrucks.length} total'),
              onTap: () {
                Navigator.pop(context);
                _showBusinessList('Food Trucks', foodTrucks);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Home Kitchens'),
              subtitle: Text('${homeKitchens.length} total'),
              onTap: () {
                Navigator.pop(context);
                _showBusinessList('Home Kitchens', homeKitchens);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Owner Portal'),
              onTap: () {
                Navigator.pop(context);
                _openOwnerPortal();
              },
            ),
          ],
        ),
      ),
      body: iconsLoaded
          ? GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: _buildMarkers(),
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}