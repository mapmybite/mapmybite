import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'menu_page.dart';
import 'owner_portal_page.dart';


import 'order_data.dart';

import 'notification_data.dart';
import 'local_notification_service.dart';
import 'orders_page.dart';
import 'favorite_data.dart';



class TruckProfilePage extends StatefulWidget {
  final Map<String, dynamic> truck;
  final bool isOwner;
  final bool initialIsFavorite;
  final bool isDarkMode;
  final ValueChanged<bool>? onFavoriteChanged;

  const TruckProfilePage({
    super.key,
    required this.truck,
    this.isOwner = false,
    this.initialIsFavorite = false,
    this.isDarkMode = false,
    this.onFavoriteChanged,
  });

  @override
  State<TruckProfilePage> createState() => _TruckProfilePageState();
}

class _TruckProfilePageState extends State<TruckProfilePage> {
  bool get _isDarkMode => widget.isDarkMode;
  Color get _pageBg => _isDarkMode ? Colors.black : Colors.white;
  Color get _cardBg => _isDarkMode ? Colors.grey.shade900 : Colors.white;
  Color get _primaryText => _isDarkMode ? Colors.white : Colors.black87;
  Color get _secondaryText => _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
  Color get _mutedText => _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get _fieldBg => _isDarkMode ? Colors.grey.shade800 : Colors.white;
  bool get isOwner => widget.isOwner;
  bool _isFavorite = false;
  Map<String, int> _selectedMenuCart = {};
  double _selectedMenuTotal = 0.0;
  List<Map<String, dynamic>> _selectedOrderItems = [];
  @override
  void initState() {
    super.initState();
    _isFavorite = FavoriteData.isFavorite(widget.truck);
  }
  Color _planColor(dynamic plan) {
    final p = plan.toString().toLowerCase();

    if (p == 'free') return Colors.grey;
    if (p == 'pro') return Colors.blue;
    if (p == 'premium') return Colors.purple;
    if (p == 'platinum') return Colors.orange;

    return Colors.grey;
  }
  bool get _canUseOrdering {
    final String plan = (widget.truck['plan'] ?? 'free').toString();
    final bool isVerified = widget.truck['isVerified'] == true;
    final bool enablePayNow = widget.truck['enablePayNow'] ?? true;

    // If Pay Now OFF → still allow ordering (Pay at Counter)
    if (!enablePayNow) return true;

    // Normal rule
    return plan != 'free' || isVerified;
  }

  bool get _isKitchen {
    final String type = (widget.truck['type'] ?? '').toString().toLowerCase();
    return type == 'kitchen' || type == 'home_kitchen';
  }

  List<String> _buildGalleryImages() {
    final dynamic gallery = widget.truck['galleryImages'];

    if (gallery is List && gallery.isNotEmpty) {
      return gallery.map((image) => image.toString()).toList();
    }

    final String mainImage = (widget.truck['image'] ?? '').toString();

    if (mainImage.isEmpty) {
      return [];
    }

    return [mainImage];
  }

  List<StoryItem> _buildStoryItems() {
    final List<StoryItem> stories = [];
    final dynamic rawStories = widget.truck['storyVideos'];

    if (rawStories is List && rawStories.isNotEmpty) {
      for (final dynamic item in rawStories) {
        if (item is Map) {
          final String path =
          (item['path'] ?? item['video'] ?? item['url'] ?? '')
              .toString()
              .trim();
          final String createdAt =
          (item['createdAt'] ?? item['storyCreatedAt'] ?? '')
              .toString()
              .trim();

          if (path.isEmpty) continue;
          if (!_storyIsActive(createdAt)) continue;
          if (!File(path).existsSync()) continue;

          stories.add(
            StoryItem(
              path: path,
              createdAt: createdAt,
              label: (item['label'] ?? item['title'] ?? 'Story').toString(),
            ),
          );
        } else {
          final String path = item.toString().trim();
          if (path.isEmpty) continue;
          if (!File(path).existsSync()) continue;

          stories.add(
            StoryItem(
              path: path,
              createdAt: '',
              label: 'Story',
            ),
          );
        }
      }
    }

    if (stories.isEmpty) {
      final String storyVideoPath =
      (widget.truck['storyVideo'] ?? '').toString().trim();
      final String storyCreatedAt =
      (widget.truck['storyCreatedAt'] ?? '').toString().trim();

      if (storyVideoPath.isNotEmpty &&
          _storyIsActive(storyCreatedAt) &&
          File(storyVideoPath).existsSync()) {
        stories.add(
          StoryItem(
            path: storyVideoPath,
            createdAt: storyCreatedAt,
            label: 'Today Story',
          ),
        );
      }
    }

    if (stories.length > 5) {
      return stories.take(5).toList();
    }

    return stories;
  }

  bool _storyIsActive(String createdAt) {
    if (createdAt
        .trim()
        .isEmpty) return true;

    try {
      final DateTime createdTime = DateTime.parse(createdAt);
      return DateTime
          .now()
          .difference(createdTime)
          .inHours < 24;
    } catch (_) {
      return true;
    }
  }

  String _buildTimingText() {
    final String timing = (widget.truck['timing'] ?? '').toString().trim();
    if (timing.isNotEmpty) return timing;

    final String openTime = (widget.truck['openTime'] ?? '').toString().trim();
    final String closeTime =
    (widget.truck['closeTime'] ?? '').toString().trim();

    if (openTime.isNotEmpty && closeTime.isNotEmpty) {
      return '$openTime - $closeTime';
    }

    if (openTime.isNotEmpty) return openTime;
    if (closeTime.isNotEmpty) return closeTime;

    return 'Timing not available';
  }

  bool _isFilePath(String path) {
    return path.startsWith('/') || path.contains(r':\');
  }

  Widget _buildImage(String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (_isFilePath(path)) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
        },
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
        );
      },
    );
  }

  String _normalizeSocialUrl(String rawUrl, String platform) {
    String value = rawUrl.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    value = value.replaceAll('@', '').trim();

    switch (platform) {
      case 'instagram':
        if (value.contains('instagram.com')) return 'https://$value';
        return 'https://instagram.com/$value';
      case 'facebook':
        if (value.contains('facebook.com')) return 'https://$value';
        return 'https://facebook.com/$value';
      case 'tiktok':
        if (value.contains('tiktok.com')) return 'https://$value';
        return 'https://www.tiktok.com/@$value';
      case 'youtube':
        if (value.contains('youtube.com') || value.contains('youtu.be')) {
          return 'https://$value';
        }
        return 'https://youtube.com/@$value';
      default:
        return 'https://$value';
    }
  }

  Future<void> _openSocialLink(String url, {String platform = ''}) async {
    final String cleanedUrl =
    platform.isNotEmpty ? _normalizeSocialUrl(url, platform) : url.trim();

    if (cleanedUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link is empty')),
      );
      return;
    }

    Uri? uri = Uri.tryParse(cleanedUrl);

    if (uri == null || uri.host.isEmpty) {
      uri = Uri.tryParse('https://$cleanedUrl');
    }

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
      );
      return;
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  Future<void> _openPhoneDialer(String phoneNumber) async {
    final String cleaned = phoneNumber.trim();
    if (cleaned.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: cleaned);
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp number not available')),
      );
      return;
    }

    final Uri uri = Uri.parse('https://wa.me/${cleaned.replaceAll('+', '')}');

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }
  double? _truckLatitude() {
    final dynamic position = widget.truck['position'];
    if (position != null && position is dynamic) {
      try {
        return (position.latitude as num).toDouble();
      } catch (_) {}
    }

    final dynamic latitude = widget.truck['latitude'];
    if (latitude is num) return latitude.toDouble();
    if (latitude is String) return double.tryParse(latitude);

    return null;
  }

  double? _truckLongitude() {
    final dynamic position = widget.truck['position'];
    if (position != null && position is dynamic) {
      try {
        return (position.longitude as num).toDouble();
      } catch (_) {}
    }

    final dynamic longitude = widget.truck['longitude'];
    if (longitude is num) return longitude.toDouble();
    if (longitude is String) return double.tryParse(longitude);

    return null;
  }

  Future<void> _openMapsAction({bool streetView = false}) async {
    final double? lat = _truckLatitude();
    final double? lng = _truckLongitude();

    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for this seller')),
      );
      return;
    }

    final Uri primaryUri = streetView
        ? Uri.parse('google.streetview:cbll=$lat,$lng')
        : Uri.parse('google.navigation:q=$lat,$lng');

    final Uri fallbackUri = streetView
        ? Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat,$lng',
    )
        : Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    bool launched = await launchUrl(
      primaryUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      launched = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            streetView
                ? 'Could not open Street View'
                : 'Could not open directions',
          ),
        ),
      );
    }
  }
  void _shareProfile() {
    final String name = widget.truck['title'] ?? 'Food Truck';
    final String cuisine = widget.truck['cuisine'] ?? '';

    final String message = 'Check out $name on MapMyBite 🍔\n$cuisine';

    Share.share(message);
  }
  Future<void> _openPos() async {
    if (!_canUseOrdering) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('POS is not available for this seller'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuPage(
          truck: widget.truck,
          isDarkMode: _isDarkMode,
          isOwnerView: true,
        ),
      ),
    );

    if (result == null || result is! Map) return;

    final rawCart = result['cart'];
    final rawTotal = result['total'];
    final rawOrderItems = result['orderItems'];

    if (rawCart is! Map) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No menu items selected')),
      );
      return;
    }

    final updatedCart = rawCart.map<String, int>(
          (key, value) => MapEntry(
        key.toString(),
        (value as num).toInt(),
      ),
    );

    if (updatedCart.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No menu items selected')),
      );
      return;
    }

    setState(() {
      _selectedMenuCart = updatedCart;
      _selectedMenuTotal = rawTotal is num ? rawTotal.toDouble() : 0.0;
      _selectedOrderItems = rawOrderItems is List
          ? rawOrderItems.cast<Map<String, dynamic>>()
          : [];
    });

    if (!mounted) return;
    _showPosCheckoutBottomSheet();
  }
  Future<void> _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerPortalPage(
          existingData: widget.truck,
          isDarkMode: _isDarkMode,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (!mounted) return;

      setState(() {
        widget.truck.addAll(result);
      });
    }
  }
  void _addToFavorite() {
    setState(() {
      FavoriteData.toggleFavorite(widget.truck);
      _isFavorite = FavoriteData.isFavorite(widget.truck);
    });

    // 🔥 send update back to main page
    if (widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!(_isFavorite);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }
  bool _isOpenNow(String timing) {
    try {
      final parts = timing.split('-');
      if (parts.length != 2) return false;

      final TimeOfDay now = TimeOfDay.now();
      final TimeOfDay open = _parseTime(parts[0].trim());
      final TimeOfDay close = _parseTime(parts[1].trim());

      final int nowMinutes = now.hour * 60 + now.minute;
      final int openMinutes = open.hour * 60 + open.minute;
      final int closeMinutes = close.hour * 60 + close.minute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } catch (_) {
      return false;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');

    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    final String period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _selectedItemsText() {
    if (_selectedOrderItems.isNotEmpty) {
      return _selectedOrderItems.map((item) {
        final String name = (item['name'] ?? '').toString();
        final int quantity = item['quantity'] is num
            ? (item['quantity'] as num).toInt()
            : 0;

        final List<String> removedOptions =
        (item['removedOptions'] is List)
            ? (item['removedOptions'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
            : [];

        final List<Map<String, dynamic>> selectedAddOns =
        (item['selectedAddOns'] is List)
            ? (item['selectedAddOns'] as List)
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (e) => e.map(
                (key, value) => MapEntry(key.toString(), value),
          ),
        )
            .toList()
            : [];

        final String notes = (item['notes'] ?? '').toString().trim();

        final List<String> extraLines = [];

        if (removedOptions.isNotEmpty) {
          extraLines.add('No ${removedOptions.join(', ')}');
        }

        if (selectedAddOns.isNotEmpty) {
          extraLines.add(
            '+ ${selectedAddOns.map((e) => e['name'].toString()).join(', ')}',
          );
        }

        if (notes.isNotEmpty) {
          extraLines.add('Note: $notes');
        }

        if (extraLines.isEmpty) {
          return '$quantity x $name';
        }

        return '$quantity x $name\n  ${extraLines.join('\n  ')}';
      }).join('\n\n');
    }

    if (_selectedMenuCart.isEmpty) return '';

    return _selectedMenuCart.entries
        .map((entry) => '${entry.value} x ${entry.key}')
        .join('\n');
  }

  List<MapEntry<String, int>> _selectedCartEntries() {
    return _selectedMenuCart.entries.toList();
  }

  String _selectedTotalQuantityText() {
    if (_selectedMenuCart.isEmpty) return '';

    int totalQty = 0;
    for (final qty in _selectedMenuCart.values) {
      totalQty += qty;
    }
    return totalQty.toString();
  }

  int _selectedTotalQuantity() {
    int totalQty = 0;
    for (final qty in _selectedMenuCart.values) {
      totalQty += qty;
    }
    return totalQty;
  }

  void _clearSelectedMenuCart() {
    setState(() {
      _selectedMenuCart = {};
      _selectedOrderItems = [];
      _selectedMenuTotal = 0.0;
    });
  }
  Widget _buildServiceBadges() {
    final bool hasDaily = widget.truck['dailySpecials'] == true;
    final bool hasCatering = widget.truck['cateringAvailable'] == true;
    final bool hasTiffin = widget.truck['tiffinService'] == true;

    if (!hasDaily && !hasCatering && !hasTiffin) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (hasDaily)
            _buildBadge(
              'Daily Specials',
              Icons.local_offer,
              Colors.orange,
              onTap: () => _showServiceInfo(
                'Today\'s Special',
                (widget.truck['dailySpecialsDetails'] ?? '').toString(),
              ),
            ),
          if (hasCatering)
            _buildBadge(
              'Catering',
              Icons.restaurant,
              Colors.blue,
              onTap: () => _showServiceInfo(
                'Catering',
                (widget.truck['cateringDetails'] ?? '').toString(),
              ),
            ),
          if (hasTiffin)
            _buildBadge(
              'Tiffin',
              Icons.lunch_dining,
              Colors.green,
              onTap: () => _showServiceInfo(
                'Tiffin Service',
                (widget.truck['tiffinDetails'] ?? '').toString(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      String text,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showServiceInfo(String title, String details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                details.trim().isEmpty ? 'No details added yet.' : details,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style:  TextStyle(fontSize: 15,color: _primaryText),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMenuItemsCard({
    required VoidCallback onClear,
    bool compact = false,
  }) {
    if (_selectedMenuCart.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = _selectedCartEntries();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Menu Items',
            style: TextStyle(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ...List.generate(entries.length, (index) {
            final item = entries[index];
            return Container(
              margin: EdgeInsets.only(
                  bottom: index == entries.length - 1 ? 0 : 8),
              padding: EdgeInsets.only(
                  bottom: index == entries.length - 1 ? 0 : 8),
              decoration: BoxDecoration(
                border: index == entries.length - 1
                    ? null
                    : Border(
                  bottom: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.key,
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'x${item.value}',
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'Total items: ${_selectedTotalQuantity()}   •   Total: \$${_selectedMenuTotal
                .toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: compact ? 12.5 : 13.5,
              color: _secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Selection'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderSummaryDialog({
    required BuildContext bottomSheetContext,
    required bool isKitchen,
    required String customerName,
    required String phone,
    required String items,
    required String quantity,
    required String dateText,
    required String timeText,
    required String notes,
    required String paymentType,
  }) async {
    final bool enablePayNow = widget.truck['enablePayNow'] ?? true;

// If Pay Now OFF → force Pay at Counter
    final String finalPaymentType =
    enablePayNow ? paymentType : 'pay_at_counter';
    final bool? confirmed = await showDialog<bool>(
      context: bottomSheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isKitchen ? 'Confirm Pre-Order' : 'Confirm Order Request',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Business', widget.truck['title'] ?? ''),
                _buildSummaryRow('Name', customerName),
                _buildSummaryRow('Phone', phone),
                _buildSummaryRow('Items', items),
                _buildSummaryRow('Quantity', quantity),
                if (_selectedMenuCart.isNotEmpty)
                  _buildSummaryRow(
                    'Estimated Total',
                    '\$${_selectedMenuTotal.toStringAsFixed(2)}',
                  ),
                _buildSummaryRow('Date', dateText),
                _buildSummaryRow(
                  isKitchen ? 'Time Slot' : 'Pickup Time',
                  timeText,
                ),
                _buildSummaryRow(
                  'Payment',
                  finalPaymentType == 'pay_now' ? 'Pay Now' : 'Pay at Counter',
                ),
                _buildSummaryRow(
                  'Notes',
                  notes.trim().isEmpty ? 'No notes' : notes,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm Request'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;

      OrderData.orders.add({
        'business': widget.truck['title'] ?? '',
        'customer': customerName,
        'phone': phone,
        'items': items,
        'quantity': quantity,
        'date': dateText,
        'time': timeText,
        'notes': notes,
        'status': 'Pending',
        'paymentType': finalPaymentType,
        'paymentMethod':
        finalPaymentType == 'pay_now' ? 'pay_now' : 'pay_at_counter',
        'paymentStatus': finalPaymentType == 'pay_now'
            ? 'Waiting for owner approval'
            : 'Pay at Counter',
        'total': _selectedMenuCart.isNotEmpty
            ? _selectedMenuTotal.toStringAsFixed(2)
            : '',
        'cashApp': widget.truck['cashApp'] ?? '',
        'zelle': widget.truck['zelle'] ?? '',
        'venmo': widget.truck['venmo'] ?? '',
        'square': widget.truck['square'] ?? '',
        'customerAtLocation': false,
        'customerLatitude': '',
        'customerLongitude': '',
        'skipLine': true,
      });
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
      NotificationData.addNotification(
        title: 'New Order',
        message: '$customerName placed a new order 🍽️',
      );
      LocalNotificationService.showNotification(
        title: 'New Order',
        body: '$customerName placed a new order 🍽️',
      );
      OrderData.addNotification(
        audience: 'owner',
        title: 'New Order',
        message: '$customerName placed a new order.',
        business: (widget.truck['title'] ?? '').toString(),
        customer: customerName,
        type: 'order',
      );

      Navigator.pop(bottomSheetContext);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finalPaymentType == 'pay_now'
                ? 'Order submitted. Wait for owner to accept and send payment options.'
                : isKitchen
                ? 'Pre-order request submitted for ${widget.truck['title']}'
                : 'Order request submitted for ${widget.truck['title']}',
          ),
        ),
      );
    }
  }
  void _showPaymentDisclaimer() {
    bool agreed = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Payment Terms'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Payment Disclaimer & Terms of Service\n",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "By proceeding, you acknowledge and agree that Mapmybite is a directory service designed to connect food vendors and customers.\n\n"
                          "Direct Transactions: Any payments made through third-party platforms (such as Cash App, Venmo, or Zelle) or in-person at the counter are direct transactions solely between you and the vendor.\n\n"
                          "No Liability: Mapmybite does not process, handle, store, or guarantee any payments. We are not responsible for any issues, disputes, financial loss, or scams that may arise from these third-party or offline transactions.\n\n"
                          "User Responsibility: You are responsible for verifying the legitimacy of the vendor and the accuracy of the payment details before sending any funds.\n\n"
                          "By checking the box below, you agree to these terms and accept full responsibility for your payment.",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (val) {
                            setState(() {
                              agreed = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "I have read and agree to the Terms of Service",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: agreed
                      ? () {
                    Navigator.pop(context);

                    // 👉 OPEN PAYMENT SCREEN AFTER AGREEMENT
                    _showCustomerPaymentOptions();
                  }
                      : null,
                  child: const Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showCustomerPaymentOptions() {
    final int orderIndex = _findLatestOrderIndexForThisTruck();

    if (orderIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active order found for this truck')),
      );
      return;
    }

    final Map<String, dynamic> order = OrderData.orders[orderIndex];

    final String paymentType =
    (order['paymentType'] ?? '').toString().trim().toLowerCase();
    final String paymentStatus =
    (order['paymentStatus'] ?? '').toString().trim().toLowerCase();

    if (paymentType != 'pay_now') {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Pay at Counter'),
            content: const Text(
              'This order is set to Pay at Counter, so no online payment options are needed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (paymentStatus == 'waiting for owner approval') {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Waiting for Owner'),
            content: const Text(
              'The owner must accept your order first. After that, payment options will be sent to you.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (paymentStatus != 'payment request sent') {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Payment Not Ready'),
            content: const Text(
              'The owner has not sent payment options yet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final String cashApp = (order['cashApp'] ?? '').toString().trim();
    final String zelle = (order['zelle'] ?? '').toString().trim();
    final String venmo = (order['venmo'] ?? '').toString().trim();
    final String square = (order['square'] ?? '').toString().trim();

    String selectedMethod = '';

    Future<void> openCustomerPaymentUrl(String url) async {
      final Uri uri = Uri.parse(url);

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment app or link')),
        );
      }
    }

    Future<void> copyCustomerPaymentValue(String label, String value) async {
      if (value.trim().isEmpty) return;

      await Clipboard.setData(ClipboardData(text: value));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied')),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Payment Options'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner sent these payment options. Pay using one of them, then tap "I Paid".',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    if (cashApp.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cash App',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(cashApp),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedMethod = 'cash_app';
                                    });
                                    openCustomerPaymentUrl(
                                      'https://cash.app/\$${cashApp.replaceAll('\$', '')}',
                                    );
                                  },
                                  child: const Text('Open'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      copyCustomerPaymentValue('Cash App', cashApp),
                                  child: const Text('Copy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (zelle.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zelle',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(zelle),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedMethod = 'zelle';
                                    });
                                    copyCustomerPaymentValue('Zelle', zelle);
                                  },
                                  child: const Text('Copy Zelle'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (venmo.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Venmo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(venmo),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedMethod = 'venmo';
                                    });
                                    openCustomerPaymentUrl(
                                      'https://venmo.com/${venmo.replaceAll('@', '')}',
                                    );
                                  },
                                  child: const Text('Open'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      copyCustomerPaymentValue('Venmo', venmo),
                                  child: const Text('Copy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (square.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Square',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(square),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedMethod = 'square';
                                    });
                                    openCustomerPaymentUrl(square);
                                  },
                                  child: const Text('Open'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      copyCustomerPaymentValue('Square', square),
                                  child: const Text('Copy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (cashApp.isEmpty &&
                        zelle.isEmpty &&
                        venmo.isEmpty &&
                        square.isEmpty)
                      const Text('No payment methods available yet.'),
                    const SizedBox(height: 10),
                    if (selectedMethod.isNotEmpty)
                      Text(
                        'Selected payment method: $selectedMethod',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
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
                  onPressed: selectedMethod.isEmpty
                      ? null
                      : () {
                    setState(() {
                      OrderData.orders[orderIndex]['paymentMethod'] = selectedMethod;
                      OrderData.orders[orderIndex]['paymentStatus'] = 'Payment Sent';

                      final String business =
                      (OrderData.orders[orderIndex]['business'] ?? '').toString();
                      final String customer =
                      (OrderData.orders[orderIndex]['customer'] ?? '').toString();

                      OrderData.addNotification(
                        audience: 'owner',
                        title: 'Payment Sent',
                        message: '$customer marked payment as sent.',
                        business: business,
                        customer: customer,
                        type: 'payment',
                      );
                      NotificationData.addNotification(
                        title: 'Payment Sent',
                        message: '$customer marked payment as sent.',
                      );
                      LocalNotificationService.showNotification(
                        title: 'Payment Sent',
                        body: '$customer marked payment as sent.',
                      );
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment marked as sent. Wait for owner to confirm payment received.',
                        ),
                      ),
                    );
                  },
                  child: const Text('I Paid'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  int _findLatestOrderIndexForThisTruck() {
    final String businessName = (widget.truck['title'] ?? '').toString().trim();

    for (int i = OrderData.orders.length - 1; i >= 0; i--) {
      final order = OrderData.orders[i];
      final String business = (order['business'] ?? '').toString().trim();

      if (business == businessName && order['orderType'] != 'pos') {
        return i;
      }
    }

    return -1;
  }

  bool _canShowImHereButton(Map<String, dynamic> order) {
    final String status = (order['status'] ?? '').toString().trim().toLowerCase();
    final String paymentType =
    (order['paymentType'] ?? '').toString().trim().toLowerCase();
    final String paymentStatus =
    (order['paymentStatus'] ?? '').toString().trim().toLowerCase();

    final bool isCompleted = status == 'completed' || status == 'rejected';
    if (isCompleted) return false;

    /// Pay at Counter → allow early check-in
    if (paymentType == 'pay_later' || paymentType == 'pay_at_counter') {
      return true;
    }

    /// Pay Now → allow only after payment is done
    if (paymentType == 'pay_now') {
      return paymentStatus == 'paid';
    }

    /// fallback (just in case)
    return status == 'accepted' ||
        status == 'preparing' ||
        status == 'ready';
  }

  Future<void> _handleImHereTap() async {
    final int orderIndex = _findLatestOrderIndexForThisTruck();

    if (orderIndex == -1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active order found for this truck')),
      );
      return;
    }

    final Map<String, dynamic> order = OrderData.orders[orderIndex];

    if (!_canShowImHereButton(order)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete payment first, then tap "I\'m Here" when you arrive'),
        ),
      );
      return;
    }

    final double? truckLat = _truckLatitude();
    final double? truckLng = _truckLongitude();

    if (truckLat == null || truckLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Truck location is not available')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission permanently denied. Open settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      truckLat,
      truckLng,
    );

    if (distanceMeters > 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be near the truck to use I\'m Here'),
        ),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final String arrivedAt =
        '${now.month}/${now.day}/${now.year} ${TimeOfDay.fromDateTime(now).format(context)}';

    setState(() {
      OrderData.markCustomerArrived(
        index: orderIndex,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distanceMeters,
        arrivedAt: arrivedAt,
      );
    });

    if (!mounted) return;



    NotificationData.addNotification(
      title: 'Customer Arrived',
      message: 'Customer has arrived at your location 📍',
    );
    LocalNotificationService.showNotification(
      title: 'Customer Arrived',
      body: 'Customer has arrived at your location 📍',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are checked in. Owner can see you now.')),
    );
  }
  void _showPosCheckoutBottomSheet() {
    if (_selectedMenuCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select menu items first')),
      );
      return;
    }

    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final customerIdController = TextEditingController();
    final notesController = TextEditingController();
    String selectedPaymentMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'POS Checkout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.truck['title'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: _primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSelectedMenuItemsCard(
                      onClear: () {
                        Navigator.pop(bottomSheetContext);
                        _clearSelectedMenuCart();
                      },
                    ),
                    const SizedBox(height: 12),
                    // Customer Name
                    TextField(
                      controller: customerNameController,
                      style: TextStyle(color: _primaryText),
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

// Phone + ID Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customerPhoneController,
                            style: TextStyle(color: _primaryText),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: customerIdController,
                            style: TextStyle(color: _primaryText),
                            decoration: InputDecoration(
                              labelText: 'MMB ID',
                              hintText: 'Optional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: selectedPaymentMethod == 'cash',
                          onSelected: (_) {
                            setModalState(() {
                              selectedPaymentMethod = 'cash';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Card'),
                          selected: selectedPaymentMethod == 'card',
                          onSelected: (_) {
                            setModalState(() {
                              selectedPaymentMethod = 'card';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Cash App'),
                          selected: selectedPaymentMethod == 'cash_app',
                          onSelected: (_) {
                            setModalState(() {
                              selectedPaymentMethod = 'cash_app';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Zelle'),
                          selected: selectedPaymentMethod == 'zelle',
                          onSelected: (_) {
                            setModalState(() {
                              selectedPaymentMethod = 'zelle';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Venmo'),
                          selected: selectedPaymentMethod == 'venmo',
                          onSelected: (_) {
                            setModalState(() {
                              selectedPaymentMethod = 'venmo';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: _primaryText),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'POS Notes',
                        hintText: 'Extra sauce, no onions, paid in cash, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          final dateText =
                              '${now.month}/${now.day}/${now.year}';
                          final timeText = TimeOfDay.now().format(context);

                          OrderData.orders.add({
                            'business': widget.truck['title'] ?? '',
                            'customer': customerNameController.text.trim().isEmpty
                                ? 'Walk-in Customer'
                                : customerNameController.text.trim(),
                            'phone': customerPhoneController.text.trim(),
                            'mmbId': customerIdController.text.trim(),
                            'items': _selectedItemsText(),
                            'quantity': _selectedTotalQuantity().toString(),
                            'date': dateText,
                            'time': timeText,
                            'notes': notesController.text.trim(),
                            'status': 'Completed',
                            'paymentType': selectedPaymentMethod,
                            'paymentMethod': selectedPaymentMethod,
                            'paymentStatus': 'Paid',
                            'total': _selectedMenuTotal.toStringAsFixed(2),
                            'cashApp': widget.truck['cashApp'] ?? '',
                            'zelle': widget.truck['zelle'] ?? '',
                            'venmo': widget.truck['venmo'] ?? '',
                            'orderType': 'pos',
                            'orderSource': 'owner_pos',
                            'createdAt': now.toIso8601String(),

                          });

                          Navigator.pop(bottomSheetContext);

                          setState(() {
                            _selectedMenuCart = {};
                            _selectedOrderItems = [];
                            _selectedMenuTotal = 0.0;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('POS order completed'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          'Complete POS Order • \$${_selectedMenuTotal.toStringAsFixed(2)}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,

                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _showOrderBottomSheet() {
    if (!_canUseOrdering) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordering is not available for this seller'),
        ),
      );
      return;
    }
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final itemsController = TextEditingController(
      text: _selectedItemsText(),
    );
    final quantityController = TextEditingController(
      text: _selectedTotalQuantityText(),
    );
    final notesController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? selectedTimeSlot;
    String selectedPaymentType = 'pay_later';

    final List<String> kitchenTimeSlots = [
      '9:00 AM - 10:00 AM',
      '12:00 PM - 1:00 PM',
      '3:00 PM - 4:00 PM',
      '5:00 PM - 6:00 PM',
      '7:00 PM - 8:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final bool isKitchen = _isKitchen;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final DateTime now = DateTime.now();
              final DateTime initialDate = selectedDate ?? now;

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: now,
                lastDate: DateTime(now.year + 1),
              );

              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            Future<void> pickTime() async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );

              if (picked != null) {
                setModalState(() {
                  selectedTime = picked;
                });
              }
            }

            String dateText() {
              if (selectedDate == null) return 'Select Date';
              return '${selectedDate!.month}/${selectedDate!
                  .day}/${selectedDate!.year}';
            }

            String timeText() {
              if (selectedTime == null) return 'Select Time';
              return selectedTime!.format(context);
            }

            return Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
                    labelStyle: TextStyle(color: _secondaryText),
                    hintStyle: TextStyle(color: _secondaryText),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDarkMode ? Colors.grey.shade600 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery
                      .of(bottomSheetContext)
                      .viewInsets
                      .bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Center(
                  child: Container(
                  width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                      Text(
                        isKitchen ? 'Schedule Pre-Order' : 'Build Your Order',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _primaryText,
                        ),
                      ),
                const SizedBox(height: 6),
                Text(
                  widget.truck['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isKitchen ? Colors.purple : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (_selectedMenuCart.isNotEmpty)...[
            _buildSelectedMenuItemsCard(
            onClear: () {
            _clearSelectedMenuCart();
            setModalState(() {
            itemsController.text = '';
            quantityController.text = '';
            });
            },
            ),
            const SizedBox(height: 12),
            ],
            TextField(
            controller: nameController,
              style: TextStyle(color: _primaryText),
            decoration: InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            const SizedBox(height: 12),
            TextField(
            controller: phoneController,
              style: TextStyle(color: _primaryText),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            const SizedBox(height: 12),
            Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
            children: [
              Expanded(
                child: Text(
                  'What would you like to order?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
              ),
            TextButton.icon(
            onPressed: () async {
            final result = await Navigator.push(
            context,
            MaterialPageRoute(
            builder: (_) => MenuPage(
            truck: widget.truck,
            isOwnerView: false,
              isDarkMode: _isDarkMode,
            ),
            ),
            );

            if (result == null || result is! Map) return;

            final rawCart = result['cart'];
            final rawTotal = result['total'];
            final rawOrderItems = result['orderItems'];

            if (rawCart is! Map) return;

            final updatedCart = rawCart.map<String, int>(
            (key, value) => MapEntry(
            key.toString(),
            (value as num).toInt(),
            ),
            );

            int totalQty = 0;
            for (final qty in updatedCart.values) {
            totalQty += qty;
            }

            setState(() {
            _selectedMenuCart = updatedCart;
            _selectedMenuTotal =
            rawTotal is num ? rawTotal.toDouble() : 0.0;

            _selectedOrderItems = rawOrderItems is List
            ? rawOrderItems.cast<Map<String, dynamic>>()
                : [];
            });

            itemsController.text =
            updatedCart.entries.map((e) => '${e.value} x ${e.key}').join(', ');

            quantityController.text = totalQty.toString();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('$totalQty item(s) added from menu'),
            ),
            );
            },
            icon: const Icon(Icons.restaurant_menu, size: 18),
            label: const Text('Browse Menu'),
            ),
            ],
            ),
            const SizedBox(height: 8),
            TextField(
            controller: itemsController,
              style: TextStyle(color: _primaryText),
            maxLines: 2,
            readOnly: _selectedMenuCart.isNotEmpty,
            decoration: InputDecoration(
            hintText: _selectedMenuCart.isNotEmpty
            ? 'Menu items selected'
                : 'Example: 2 tacos, 1 burrito, 1 mango lassi',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _selectedMenuCart.isNotEmpty
            ? IconButton(
            onPressed: () {
            _clearSelectedMenuCart();
            setModalState(() {
            itemsController.text = '';
            quantityController.text = '';
            });
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear menu selection',
            )
                : null,
            ),
            ),
            ],
            ),
            const SizedBox(height: 12),
            TextField(
            controller: quantityController,
              style: TextStyle(color: _primaryText),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            const SizedBox(height: 14),
            SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(dateText()),
            style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            ),
            const SizedBox(height: 12),
            isKitchen
            ? DropdownButtonFormField<String>(
            value: selectedTimeSlot,
            decoration: InputDecoration(
            labelText: 'Select Time Slot',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            items: kitchenTimeSlots.map((slot) {
            return DropdownMenuItem<String>(
            value: slot,
            child: Text(slot),
            );
            }).toList(),
            onChanged: (value) {
            setModalState(() {
            selectedTimeSlot = value;
            });
            },
            )
                : SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
            onPressed: pickTime,
            icon: const Icon(Icons.access_time),
            label: Text(timeText()),
            style: OutlinedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            ),
            const SizedBox(height: 8),
            Text(
            isKitchen
            ? 'Choose your preferred pickup date and available time slot.'
                : 'Choose your preferred pickup date and time.',
              style: TextStyle(
                fontSize: 13,
                color: _secondaryText,
              ),
            ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        style: TextStyle(color: _primaryText),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Spicy level, no onions, extra sauce, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Payment Option',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Pay at Counter',
                                style: TextStyle(color: _primaryText),
                              ),
                              value: 'pay_later',
                              groupValue: selectedPaymentType,
                              onChanged: (value) {
                                if (value == null) return;
                                setModalState(() {
                                  selectedPaymentType = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Pay Now',
                                style: TextStyle(color: _primaryText),
                              ),
                              value: 'pay_now',
                              groupValue: selectedPaymentType,
                              onChanged: (widget.truck['enablePayNow'] ?? true)
                                  ? (value) {
                                if (value == null) return;
                                setModalState(() {
                                  selectedPaymentType = value;
                                });
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
            onPressed: () async {
            final bool missingRequired =
            nameController.text.trim().isEmpty ||
            phoneController.text.trim().isEmpty ||
            itemsController.text.trim().isEmpty ||
            quantityController.text.trim().isEmpty ||
            selectedDate == null ||
            (isKitchen
            ? selectedTimeSlot == null
                : selectedTime == null);

            if (missingRequired) {
            ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
            content: Text(
            'Please fill all required fields and select date and time',
            ),
            ),
            );
            return;
            }

            final String finalDateText =
            '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}';
            final String finalTimeText = isKitchen
            ? selectedTimeSlot!
                : selectedTime!.format(this.context);

            await _showOrderSummaryDialog(
              bottomSheetContext: bottomSheetContext,
              isKitchen: isKitchen,
              customerName: nameController.text.trim(),
              phone: phoneController.text.trim(),
              items: itemsController.text.trim(),
              quantity: quantityController.text.trim(),
              dateText: finalDateText,
              timeText: finalTimeText,
              notes: notesController.text.trim(),
              paymentType: selectedPaymentType,
            );

            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Review Order Summary'),
            style: ElevatedButton.styleFrom(
            backgroundColor:
            isKitchen ? Colors.purple : Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            ),
            ),
            const SizedBox(height: 10),
            ],
            ),
            )
            ,
                ));
          },
        );
      },
    );
  }

  Widget _buildPremiumSocialIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required List<Color> colors,
    Color iconColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }
  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> colors,
  }) {
    return Expanded(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> galleryImages = _buildGalleryImages();
    final List<StoryItem> stories = _buildStoryItems();

    final String imagePath = (widget.truck['image'] ?? '')
        .toString()
        .isNotEmpty
        ? (widget.truck['image'] ?? '').toString()
        : (galleryImages.isNotEmpty ? galleryImages.first : '');

    final String timingText = _buildTimingText();
    final bool isOpen = timingText.contains('-')
        ? _isOpenNow(timingText)
        : false;

    final String instagram = (widget.truck['instagram'] ?? '').toString();
    final String facebook = (widget.truck['facebook'] ?? '').toString();
    final String tiktok = (widget.truck['tiktok'] ?? '').toString();
    final String youtube = (widget.truck['youtube'] ?? '').toString();
    final String whatsapp =
    (widget.truck['whatsapp'] ?? widget.truck['phone'] ?? '').toString();
    final String phone = (widget.truck['phone'] ?? '').toString();
    final double? lat = _truckLatitude();
    final double? lng = _truckLongitude();
    final bool hasMapLocation = lat != null && lng != null;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : null,
        foregroundColor: _isDarkMode ? Colors.white : null,
        title: Text(widget.truck['title'] ?? 'Business Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imagePath.isNotEmpty
                ? _buildImage(
              imagePath,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 240,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.truck['title'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // ✅ VERIFIED
                      if (widget.truck['isVerified'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blue, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(width: 8),

                      // ✅ PLAN
                      if (widget.truck['plan'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _planColor(widget.truck['plan']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.truck['plan'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _planColor(widget.truck['plan']),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.truck['cuisine'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  color: _isKitchen ? Colors.purple : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildServiceBadges(),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final stories = _buildStoryItems();
                      if (stories.isEmpty) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenStoryViewerPage(
                            stories: stories,
                            initialIndex: 0,
                            title: widget.truck['title'] ?? 'Story',
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 3),
                          ),
                          child: const ClipOval(
                            child: ColoredBox(color: Colors.black),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_buildStoryItems().length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _shareProfile,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                           Text(
                            "Share",
                            style: TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _openMapsAction();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Directions",
                            style: TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _addToFavorite,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: _isFavorite ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
    ),

    const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (widget.truck['phone'] ?? '').toString(),
                      style: TextStyle(
                        color: _primaryText,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final String phone = (widget.truck['phone'] ?? '')
                          .toString();
                      if (phone
                          .trim()
                          .isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number not available'),
                          ),
                        );
                        return;
                      }
                      await _openPhoneDialer(phone);
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (instagram.isNotEmpty ||
                facebook.isNotEmpty ||
                tiktok.isNotEmpty ||
                youtube.isNotEmpty ||
                whatsapp.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (instagram.isNotEmpty)
                            _buildPremiumSocialIcon(
                              icon: Icons.camera_alt,
                              tooltip: 'Instagram',
                              colors: const [
                                Color(0xFF833AB4),
                                Color(0xFFE1306C),
                                Color(0xFFFCAF45),
                              ],
                              onTap: () =>
                                  _openSocialLink(
                                    instagram,
                                    platform: 'instagram',
                                  ),
                            ),
                          if (facebook.isNotEmpty)
                            _buildPremiumSocialIcon(
                              icon: Icons.facebook,
                              tooltip: 'Facebook',
                              colors: const [
                                Color(0xFF1877F2),
                                Color(0xFF0A58CA),
                              ],
                              onTap: () =>
                                  _openSocialLink(
                                    facebook,
                                    platform: 'facebook',
                                  ),
                            ),
                          if (tiktok.isNotEmpty)
                            _buildPremiumSocialIcon(
                              icon: Icons.music_note,
                              tooltip: 'TikTok',
                              colors: const [
                                Color(0xFF111111),
                                Color(0xFF25F4EE),
                                Color(0xFFFE2C55),
                              ],
                              onTap: () =>
                                  _openSocialLink(
                                    tiktok,
                                    platform: 'tiktok',
                                  ),
                            ),
                          if (youtube.isNotEmpty)
                            _buildPremiumSocialIcon(
                              icon: Icons.play_arrow_rounded,
                              tooltip: 'YouTube',
                              colors: const [
                                Color(0xFFFF0000),
                                Color(0xFFCC0000),
                              ],
                              onTap: () =>
                                  _openSocialLink(
                                    youtube,
                                    platform: 'youtube',
                                  ),
                            ),
                          if (whatsapp.isNotEmpty)
                            _buildPremiumSocialIcon(
                              icon: Icons.message_rounded,
                              tooltip: 'WhatsApp',
                              colors: const [
                                Color(0xFF25D366),
                                Color(0xFF128C7E),
                              ],
                              onTap: () => _openWhatsApp(whatsapp),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isOwner
                  ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPos,
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('POS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrdersPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Orders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )

                  : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!_canUseOrdering) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This seller has not enabled in-app ordering yet. Please contact them directly.',
                                  ),
                                ),
                              );
                              return;
                            }

                            _showOrderBottomSheet();
                          },
                          icon: Icon(
                            _isKitchen ? Icons.schedule : Icons.shopping_bag,
                          ),
                          label: Text(
                            !_canUseOrdering
                                ? 'Contact Seller'
                                : (_isKitchen ? 'Schedule Pre-Order' : 'Build Order'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            _isKitchen ? Colors.purple : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleImHereTap,
                      icon: const Icon(Icons.location_on),
                      label: const Text("I'm Here"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showPaymentDisclaimer,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pay Now / Payment Options'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timingText,
                      style: TextStyle(
                        color: _secondaryText,
                      ),
                    ),
                  ),
                  if (timingText.contains('-')) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          color: isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
             Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Food Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: galleryImages.isNotEmpty
                  ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenGalleryPage(
                                images: galleryImages,
                                initialIndex: index,
                              ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildImage(
                        galleryImages[index],
                        width: 150,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Text(
                  'No food photos available',
                  style: TextStyle(color: _secondaryText),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Daily Special',
                style: TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                  _isKitchen ? Colors.purple.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.truck['dailySpecial'] ??
                      'No daily special available today',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
             Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuPage(
                          truck: widget.truck,
                          isDarkMode: _isDarkMode,
                        )
                      ),
                    );

                    if (result != null && result is Map) {
                      final dynamic rawCart = result['cart'];
                      final dynamic rawTotal = result['total'];

                      if (rawCart is Map) {
                        setState(() {
                          _selectedMenuCart = rawCart.map<String, int>(
                                (key, value) =>
                                MapEntry(
                                  key.toString(),
                                  (value as num).toInt(),
                                ),
                          );
                          _selectedMenuTotal =
                          rawTotal is num ? rawTotal.toDouble() : 0.0;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${_selectedTotalQuantity()} item(s) added from menu',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('View Full Menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedMenuCart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected for Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ..._selectedMenuCart.entries.map(
                            (entry) =>
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'x${entry.value}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        'Total items: ${_selectedTotalQuantity()}   •   Total: \$${_selectedMenuTotal
                            .toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearSelectedMenuCart,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Selection'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
             Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                (widget.truck['description'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: _mutedText,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class StoryItem {
  final String path;
  final String createdAt;
  final String label;

  StoryItem({
    required this.path,
    required this.createdAt,
    required this.label,
  });
}

class FullScreenStoryViewerPage extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;
  final String title;

  const FullScreenStoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<FullScreenStoryViewerPage> createState() =>
      _FullScreenStoryViewerPageState();
}

class _FullScreenStoryViewerPageState extends State<FullScreenStoryViewerPage> {
  VideoPlayerController? _videoController;
  late int _currentIndex;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadCurrentStory();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStory() async {
    final oldController = _videoController;

    setState(() {
      _isLoading = true;
      _isPlaying = false;
      _videoController = null;
    });

    await oldController?.dispose();

    final String path = widget.stories[_currentIndex].path;
    final VideoPlayerController controller =
    VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.seekTo(Duration.zero);
      await controller.play();

      controller.addListener(() async {
        if (!mounted) return;
        if (_videoController != controller) return;

        final value = controller.value;
        final bool finished = value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration &&
            !value.isPlaying;

        if (finished) {
          if (_currentIndex < widget.stories.length - 1) {
            await _goToStory(_currentIndex + 1);
          } else {
            setState(() {
              _isPlaying = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {});
          }
        }
      });

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isLoading = false;
        _isPlaying = true;
      });
    } catch (e) {
      await controller.dispose();

      if (!mounted) return;

      setState(() {
        _videoController = null;
        _isLoading = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _videoController!.play();
      if (!mounted) return;
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _goToStory(int index) async {
    if (index < 0 || index >= widget.stories.length) return;

    setState(() {
      _currentIndex = index;
    });

    await _loadCurrentStory();
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(widget.stories.length, (index) {
        double progress = 0;

        if (index < _currentIndex) {
          progress = 1;
        } else if (index == _currentIndex &&
            _videoController != null &&
            _videoController!.value.isInitialized &&
            _videoController!.value.duration.inMilliseconds > 0) {
          progress = _videoController!.value.position.inMilliseconds /
              _videoController!.value.duration.inMilliseconds;
          if (progress > 1) progress = 1;
          if (progress < 0) progress = 0;
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == widget.stories.length - 1 ? 0 : 4,
            ),
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : _videoController != null &&
                  _videoController!.value.isInitialized
                  ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) async {
                  final screenWidth = MediaQuery
                      .of(context)
                      .size
                      .width;
                  final dx = details.localPosition.dx;

                  if (dx < screenWidth * 0.3) {
                    await _goToStory(_currentIndex - 1);
                  } else if (dx > screenWidth * 0.7) {
                    await _goToStory(_currentIndex + 1);
                  } else {
                    await _togglePlayPause();
                  }
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
                  : const Center(
                child: Text(
                  'Could not load story',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  _buildProgressBars(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1}/${widget.stories.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isLoading && !_isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 72,
                ),
              ),
            Positioned(
              bottom: 18,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Text(
                    currentStory.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap left for previous • center to pause/play • right for next',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
}

class FullScreenGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGalleryPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGalleryPage> createState() => _FullScreenGalleryPageState();
}

class _FullScreenGalleryPageState extends State<FullScreenGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  bool _isFilePath(String path) {
    return path.startsWith('/') || path.contains(r':\');
  }

  Widget _buildImage(String path) {
    if (_isFilePath(path)) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.white, size: 80);
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.white, size: 80);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: _buildImage(widget.images[index]),
            ),
          );
        },
      ),
    );
  }
  bool _isFavorite = false;

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming next')),
    );
  }

  void _openDirections() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions feature coming next')),
    );
  }

  void _addToFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }

  Widget _smallActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

}