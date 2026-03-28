import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'owner_portal_page.dart';
import 'truck_profile_page.dart';

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
      'description': 'Fresh Mexican street food in Stockton.',
      'image': 'assets/images/mexican_food.jpg',
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
      'description': 'Quick and tasty fast food favorites.',
      'image': 'assets/images/fast_food.jpg',
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
      'description': 'Flavorful Indian food on the go.',
      'image': 'assets/images/indian_food.jpg',
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
      'description': 'Punjabi comfort food with a fun twist.',
      'image': 'assets/images/punjabi_food.jpg',
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
      'description': 'Homestyle Punjabi meals made fresh daily.',
      'image': 'assets/images/home_food.jpg',
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
      'description': 'Fresh vegetarian home kitchen meals.',
      'image': 'assets/images/home_food.jpg',
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
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerPortalPage(),
                  ),
                );
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