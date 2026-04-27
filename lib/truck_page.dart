import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_text.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'owner_portal_page.dart';
import 'truck_profile_page.dart';
import 'orders_page.dart';
import 'customer_order_history_page.dart';
import 'package:mapmybite/notification_data.dart';
import 'package:mapmybite/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class TruckPage extends StatefulWidget {
  final bool openOwnerPortalOnStart;

  const TruckPage({
    super.key,
    this.openOwnerPortalOnStart = false,
  });

  @override
  State<TruckPage> createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  GoogleMapController? mapController;

  BitmapDescriptor? truckIcon;
  BitmapDescriptor? homeKitchenIcon;

  bool iconsLoaded = false;
  bool _isOpeningProfile = false;
  bool _locationPermissionGranted = false;
  bool _didTryInitialUserCenter = false;
  Map<String, dynamic>? _ownerBusiness;
  // Customer page filters
  String _searchQuery = '';
  String _selectedCuisine = 'All';
  bool _isListView = false;
  Set<String> _favoriteIds = {};
  bool _showFavoritesOnly = false;
  LatLng? _searchCenterPosition;
  double _searchRadiusMiles = 25;
  Future<void> _fitMapToFilteredResults() async {
    final items = _filteredVendors;

    if (items.isEmpty || mapController == null) return;

    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (var item in items) {
      final LatLng pos = _getLatLngFromItem(item);

      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }
  final List<String> _cuisineFilters = [
    'All',
    'Mexican Food',
    'Fast Food',
    'Indian Food',
    'Punjabi Food',
    'Punjabi Home Food',
    'Indian Vegetarian',
  ];

  static const LatLng _defaultUsaPosition = LatLng(37.9577, -121.2908);
  LatLng _initialPosition = _defaultUsaPosition;
  LatLng? _currentUserPosition;

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
  // Combine all vendors
  List<Map<String, dynamic>> get _allVendors {
    return [...foodTrucks, ...homeKitchens];
  }

// Apply search + cuisine filter
  List<Map<String, dynamic>> get _filteredVendors {
    final results = _allVendors.where((vendor) {
      final id = vendor['id'].toString();

      String cleanSearchText(String text) {
        return text
            .toLowerCase()
            .replaceAll(RegExp(r'\b(food|cuisine|truck|kitchen|restaurant|near|me)\b'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final String query = cleanSearchText(_searchQuery);

      final String searchableText = cleanSearchText([
        vendor['title'],
        vendor['cuisine'],
        vendor['type'],
        vendor['menu'],
        vendor['description'],
      ].map((value) => value?.toString() ?? '').join(' '));

      final List<String> queryWords =
      query.split(' ').where((word) => word.trim().isNotEmpty).toList();

      final bool matchesSearch = queryWords.isEmpty ||
          queryWords.any((word) => searchableText.contains(word));

      final matchesCuisine = _selectedCuisine == 'All' ||
          vendor['cuisine'] == _selectedCuisine;

      final matchesFavorites =
          !_showFavoritesOnly || _favoriteIds.contains(id);

      bool matchesRadius = true;

      if (_searchCenterPosition != null) {
        final LatLng vendorPosition = _getLatLngFromItem(vendor);

        final double meters = Geolocator.distanceBetween(
          _searchCenterPosition!.latitude,
          _searchCenterPosition!.longitude,
          vendorPosition.latitude,
          vendorPosition.longitude,
        );

        final double miles = meters / 1609.34;
        matchesRadius = miles <= _searchRadiusMiles;
      }

      return matchesSearch && matchesCuisine && matchesFavorites && matchesRadius;
    }).toList();

    // 🔥 sort by distance
    if (_currentUserPosition != null) {
      results.sort(
            (a, b) => _distanceInMilesToVendor(a)
            .compareTo(_distanceInMilesToVendor(b)),
      );
    }

    return results;
  }

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.openOwnerPortalOnStart) {
        await _openOwnerPortal();
      }
    });
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

      if (!mounted) return;

      setState(() {
        truckIcon = truckData != null
            ? BitmapDescriptor.fromBytes(truckData.buffer.asUint8List())
            : null;
        homeKitchenIcon = kitchenData != null
            ? BitmapDescriptor.fromBytes(kitchenData.buffer.asUint8List())
            : null;
        iconsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading icons: $e');
      if (!mounted) return;
      setState(() {
        iconsLoaded = true;
      });
    }
  }

  Future<void> _initializeUserLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!mounted) return;

      setState(() {
        _locationPermissionGranted = hasPermission;
      });

      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentUserPosition = userLatLng;
        _initialPosition = userLatLng;
      });

      if (mapController != null && !_didTryInitialUserCenter) {
        _didTryInitialUserCenter = true;
        await _animateToLocation(userLatLng, zoom: 13);
      }
    } catch (e) {
      debugPrint('Location init error: $e');
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please turn on location services'),
        ),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied'),
        ),
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Location permission permanently denied. Open app settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    return true;
  }

  LatLng _getLatLngFromItem(Map<String, dynamic> item) {
    if (item['position'] is LatLng) {
      return item['position'] as LatLng;
    }

    return LatLng(
      ((item['latitude'] ?? _defaultUsaPosition.latitude) as num).toDouble(),
      ((item['longitude'] ?? _defaultUsaPosition.longitude) as num).toDouble(),
    );
  }

  Future<void> _animateToLocation(
      LatLng target, {
        double zoom = 12,
      }) async {
    if (mapController == null) return;

    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
    );
  }

  Future<void> _centerOnBusiness(
      Map<String, dynamic> item, {
        double zoom = 15,
      }) async {
    final target = _getLatLngFromItem(item);
    await _animateToLocation(target, zoom: zoom);
  }

  Future<void> _centerOnUserLocation() async {
    setState(() {
      _searchCenterPosition = null;
      _searchQuery = '';
      _showFavoritesOnly = false;
    });
    if (_currentUserPosition != null) {
      await _animateToLocation(_currentUserPosition!, zoom: 13);
      return;
    }

    await _initializeUserLocation();

    if (_currentUserPosition != null) {
      await _animateToLocation(_currentUserPosition!, zoom: 13);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not get current location. Showing California.'),
      ),
    );

    await _animateToLocation(_defaultUsaPosition, zoom: 9);
  }
  Future<void> _searchCityOrArea(String text) async {
    final String query = text.trim();

    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find "$query"')),
        );
        return;
      }

      final target = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      setState(() {
        _searchCenterPosition = target;
        _searchQuery = '';
        _showFavoritesOnly = false;
      });

      await _animateToLocation(target, zoom: 10.5);

      if (!mounted) return;

      final nearbyCount = _filteredVendors.length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          nearbyCount == 0 ? Colors.black87 : Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.all(14),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                nearbyCount == 0 ? Icons.location_off : Icons.location_on,
                color: nearbyCount == 0 ? Colors.orange : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nearbyCount == 0
                      ? 'Showing $query\nNo vendors here yet. Invite food trucks or home kitchens to join MapMyBite — it’s free!'
                      : 'Showing $query\n$nearbyCount vendor(s) available within ${_searchRadiusMiles.toInt()} miles.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('City search error: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not search "$query"')),
      );
    }
  }

  Future<void> _openBusinessFromMap(Map<String, dynamic> item) async {
    await _centerOnBusiness(item, zoom: 15);
    if (!mounted) return;
    _openProfilePage(item);
  }

  void _openProfilePage(
      Map<String, dynamic> item, {
        bool isOwner = false,
      }) {
    if (_isOpeningProfile) return;

    _isOpeningProfile = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckProfilePage(
          truck: item,
          isOwner: isOwner,
          initialIsFavorite: _favoriteIds.contains(item['id'].toString()),
          onFavoriteChanged: (isFavorite) {
            setState(() {
              final id = item['id'].toString();

              if (isFavorite) {
                _favoriteIds.add(id);
              } else {
                _favoriteIds.remove(id);
              }
              _saveFavorites();
            });
          },
        ),
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
    if (!mounted) return;

    final bool isFoodTruck = result['type'] == 'food_truck';

    final double latitude = ((result['latitude'] ?? 37.9577) as num).toDouble();
    final double longitude =
    ((result['longitude'] ?? -121.2908) as num).toDouble();

    final Map<String, dynamic> newBusiness = {
      'id': result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': result['title'] ?? '',
      'cuisine': result['cuisine'] ?? '',
      'plan': result['plan'] ?? 'free',
      'enablePayNow': result['enablePayNow'] ?? true,
      'isVerified': result['isVerified'] ?? false,
      'position': LatLng(latitude, longitude),
      'latitude': latitude,
      'longitude': longitude,
      'type': isFoodTruck ? 'truck' : 'kitchen',
      'phone': result['phone'] ?? '',
      'timing': _buildTimingFromResult(result),
      'openTime': result['openTime'] ?? '',
      'closeTime': result['closeTime'] ?? '',
      'address': result['address'] ?? '',
      'menu': result['menu'] ?? '',
      'menuItems': result['menuItems'] ?? [],
      'description': result['description'] ?? '',

      'dailySpecials': result['dailySpecials'] ?? false,
      'dailySpecialsDetails': result['dailySpecialsDetails'] ?? '',
      'cateringAvailable': result['cateringAvailable'] ?? false,
      'cateringDetails': result['cateringDetails'] ?? '',
      'tiffinService': result['tiffinService'] ?? false,
      'tiffinDetails': result['tiffinDetails'] ?? '',

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
      _ownerBusiness = newBusiness;

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

    await Future.delayed(const Duration(milliseconds: 250));
    await _centerOnBusiness(newBusiness, zoom: 15);

    if (!mounted) return;
    _openProfilePage(newBusiness, isOwner: true);
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
    final List<String> gallery =
    _normalizeGalleryImages(result['galleryImages']);
    if (gallery.isNotEmpty) return gallery.first;
    return '';
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    for (final item in _filteredVendors) {
      markers.add(
        Marker(
          markerId: MarkerId(item['id'].toString()),
          position: _getLatLngFromItem(item),
          icon: item['type'] == 'truck'
              ? (truckIcon ?? BitmapDescriptor.defaultMarker)
              : (homeKitchenIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              )),
          infoWindow: InfoWindow(title: item['title']?.toString() ?? ''),
          onTap: () async {
            await _openBusinessFromMap(item);
          },
        ),
      );
    }

    return markers;
  }
  Set<Circle> _buildRadiusCircles() {
    if (_searchCenterPosition == null) return {};

    return {
      Circle(
        circleId: const CircleId('search_radius'),
        center: _searchCenterPosition!,
        radius: _searchRadiusMiles * 1609.34,
        fillColor: Colors.orange.withOpacity(0.12),
        strokeColor: Colors.orange,
        strokeWidth: 2,
      ),
    };
  }
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;

    setState(() {
      _favoriteIds = saved.toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }
  void _showActiveAreas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Active Areas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'MapMyBite is currently focusing on these areas first:',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                _activeAreaTile('Stockton, CA', 'Food trucks and home kitchens'),
                _activeAreaTile('Manteca, CA', 'Coming soon'),
                _activeAreaTile('Lathrop, CA', 'Coming soon'),
                _activeAreaTile('French Camp, CA', 'Coming soon'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text(
                    'No vendors near you yet? Invite a food truck or home kitchen to join MapMyBite — it’s free to grow your food business!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: Colors.green,
                      ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _activeAreaTile(String city, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place, color: Colors.orange),
      title: Text(
        city,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    );
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
                            item['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${item['cuisine'] ?? ''}\n'
                                  '${item['timing'] ?? ''}\n'
                                  '${_distanceInMilesToVendor(item) == 999999
                                  ? 'Distance not available'
                                  : '${_distanceInMilesToVendor(item).toStringAsFixed(1)} mi away'}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing:
                          const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              if (!mounted) return;
                              await _centerOnBusiness(item, zoom: 15);
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
  Widget _buildCustomerSearchPanel() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                  hintText: 'Search food trucks or kitchens',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _selectedCuisine = 'All';
                  });

                  Future.delayed(const Duration(milliseconds: 300), () {
                    _fitMapToFilteredResults();
                  });
                },
                onSubmitted: (value) {
                  final text = value.trim().toLowerCase();

                  final looksLikeCity =
                      text.contains(',') ||
                          text.contains(' ca') ||
                          text.contains(' california');

                  if (looksLikeCity) {
                    _searchCityOrArea(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cuisineFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cuisine = _cuisineFilters[index];
                  final selected = cuisine == _selectedCuisine;

                  return ChoiceChip(
                    label: Text(cuisine),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCuisine = cuisine;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

// Map / List toggle
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showFavoritesOnly
                          ? Colors.pink.shade50
                          : Colors.grey.shade100,
                      side: BorderSide(
                        color: _showFavoritesOnly
                            ? Colors.pink.shade200
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: Icon(
                      _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                      color: Colors.pink,
                    ),
                    label: Text(
                      'Favorites (${_favoriteIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                        _isListView = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    side: BorderSide(color: Colors.indigo.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.location_on, color: Colors.indigo),
                  label: const Text(
                    'Areas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showActiveAreas,
                ),
                const SizedBox(width: 10),
                const Text(
                  'List',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isListView,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.orange,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.orange.shade200,
                  onChanged: (value) {
                    setState(() {
                      _isListView = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Color _cuisineBadgeColor(String cuisine) {
    final text = cuisine.toLowerCase();

    if (text.contains('mexican')) return Colors.green;
    if (text.contains('indian') || text.contains('punjabi')) return Colors.orange;
    if (text.contains('fast')) return Colors.red;
    if (text.contains('vegetarian')) return Colors.purple;
    if (text.contains('home')) return Colors.deepPurple;

    // 🌎 NEW: smart fallback colors
    if (text.contains('chinese')) return Colors.redAccent;
    if (text.contains('italian')) return Colors.green.shade700;
    if (text.contains('thai')) return Colors.teal;
    if (text.contains('mediterranean')) return Colors.blue;
    if (text.contains('american')) return Colors.indigo;

    // fallback
    return Colors.blueGrey;
  }
  bool _isOpenNow(String timing) {
    try {
      final parts = timing.split('-');
      if (parts.length != 2) return false;

      final now = TimeOfDay.now();

      TimeOfDay parseTime(String t) {
        final time = t.trim().toLowerCase();
        final isPM = time.contains('pm');
        final cleaned = time.replaceAll(RegExp(r'[^0-9:]'), '');
        final split = cleaned.split(':');

        int hour = int.parse(split[0]);
        int minute = split.length > 1 ? int.parse(split[1]) : 0;

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }

      final start = parseTime(parts[0]);
      final end = parseTime(parts[1]);

      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } catch (e) {
      return false;
    }
  }
  Widget _buildListView() {
    final items = _filteredVendors;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No food trucks or home kitchens available here right now',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Help grow MapMyBite in your area.\nInvite vendors to join — it’s free!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 130, 12, 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          elevation: 4,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
              item['title']?.toString() ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cuisineBadgeColor(item['cuisine'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['cuisine'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _cuisineBadgeColor(item['cuisine'] ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(item['timing'] ?? ''),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isOpenNow(item['timing'] ?? '')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isOpenNow(item['timing'] ?? '') ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isOpenNow(item['timing'] ?? '')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _distanceInMilesToVendor(item) == 999999
                      ? 'Distance not available'
                      : '${_distanceInMilesToVendor(item).toStringAsFixed(1)} mi away',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(
                _favoriteIds.contains(item['id'].toString())
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _favoriteIds.contains(item['id'].toString())
                    ? Colors.red
                    : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  final id = item['id'].toString();

                  if (_favoriteIds.contains(id)) {
                    _favoriteIds.remove(id);
                  } else {
                    _favoriteIds.add(id);
                  }
                  _saveFavorites();
                });
              },
            ),
            onTap: () {
              _openProfilePage(item);
            },
          ),
        );
      },
    );
  }
  double _distanceInMilesToVendor(Map<String, dynamic> item) {
    if (_currentUserPosition == null) return 999999;

    final LatLng vendorPosition = _getLatLngFromItem(item);

    final double meters = Geolocator.distanceBetween(
      _currentUserPosition!.latitude,
      _currentUserPosition!.longitude,
      vendorPosition.latitude,
      vendorPosition.longitude,
    );

    return meters / 1609.34;
  }
  Future<void> _goToMapHome() async {
    Navigator.pop(context);

    if (_currentUserPosition != null) {
      await _animateToLocation(_currentUserPosition!, zoom: 13);
      return;
    }

    await _animateToLocation(_defaultUsaPosition, zoom: 9);
  }

  void _openCustomerOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerOrderHistoryPage(),
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
        actions: [
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long),
            onPressed: _openCustomerOrderHistory,
          ),
          IconButton(
            tooltip: 'My Location',
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
          ),
          ValueListenableBuilder<List<Map<String, String>>>(
            valueListenable: NotificationData.notifications,
            builder: (context, notifications, _) {
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  if (notifications.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notifications.length > 9
                              ? '9+'
                              : notifications.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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
              title: Text(AppText.home()),
              onTap: _goToMapHome,
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(AppText.myLocation()),
              onTap: () {
                Navigator.pop(context);
                _centerOnUserLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(AppText.orders()),
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
              leading: const Icon(Icons.language),
              title: Text(AppText.languageLabel()),
              onTap: () {
                Navigator.pop(context);

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppText.chooseLanguage(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ListTile(
                            leading: const Text('🇺🇸'),
                            title: const Text('English'),
                            onTap: () {
                              setState(() {
                                AppText.language = 'en';
                              });
                              Navigator.pop(context);
                            },
                          ),

                          ListTile(
                            leading: const Text('🇪🇸'),
                            title: const Text('Español'),
                            onTap: () {
                              setState(() {
                                AppText.language = 'es';
                              });
                              Navigator.pop(context);
                            },
                          ),

                          ListTile(
                            leading: const Text('🇮🇳'),
                            title: const Text('हिन्दी'),
                            onTap: () {
                              setState(() {
                                AppText.language = 'hi';
                              });
                              Navigator.pop(context);
                            },
                          ),

                          ListTile(
                            leading: const Text('🇮🇳'),
                            title: const Text('ਪੰਜਾਬੀ'),
                            onTap: () {
                              setState(() {
                                AppText.language = 'pa';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text(AppText.foodTrucks()),
              subtitle: Text('${foodTrucks.length} total'),
              onTap: () {
                Navigator.pop(context);
                _showBusinessList('Food Trucks', foodTrucks);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: Text(AppText.homeKitchens()),
              subtitle: Text('${homeKitchens.length} total'),
              onTap: () {
                Navigator.pop(context);
                _showBusinessList('Home Kitchens', homeKitchens);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('My Favorites'),
              subtitle: Text('${_favoriteIds.length} saved'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _showFavoritesOnly = true;
                  _isListView = true;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppText.ownerPortal()),
              onTap: () {
                Navigator.pop(context);
                _openOwnerPortal();
              },
            ),
            if (_ownerBusiness != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit My Profile'),
                onTap: () async {
                  Navigator.pop(context);

                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerPortalPage(
                        existingData: _ownerBusiness,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      final String editedId = result['id']?.toString() ?? '';

                      _ownerBusiness = {
                        ...?_ownerBusiness,
                        ...result,
                      };

                      final int truckIndex = foodTrucks.indexWhere(
                            (truck) => truck['id']?.toString() == editedId,
                      );

                      final int kitchenIndex = homeKitchens.indexWhere(
                            (kitchen) => kitchen['id']?.toString() == editedId,
                      );

                      if (truckIndex != -1) {
                        foodTrucks[truckIndex].addAll(result);
                      }

                      if (kitchenIndex != -1) {
                        homeKitchens[kitchenIndex].addAll(result);
                      }
                    });
                  }
                },
              ),
          ],
        ),
      ),
      body: iconsLoaded
          ? Stack(
        children: [
          _isListView
              ? _buildListView()
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 9,
            ),
            mapType: MapType.normal,
            onMapCreated: (controller) async {
              mapController = controller;

              if (_currentUserPosition != null &&
                  !_didTryInitialUserCenter) {
                _didTryInitialUserCenter = true;
                await _animateToLocation(_currentUserPosition!, zoom: 13);
              }
            },
            markers: _buildMarkers(),
            circles: _buildRadiusCircles(),
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: _locationPermissionGranted,
            zoomControlsEnabled: true,
          ),
          _buildCustomerSearchPanel(),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}