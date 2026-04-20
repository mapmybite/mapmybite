import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'owner_menu_editor_page.dart';

class OwnerPortalPage extends StatefulWidget {
  const OwnerPortalPage({super.key});

  @override
  State<OwnerPortalPage> createState() => _OwnerPortalPageState();
}

class _OwnerPortalPageState extends State<OwnerPortalPage> {
  String businessType = 'food_truck';
  String selectedPlan = 'free';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController cuisineController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController openTimeController = TextEditingController();
  final TextEditingController closeTimeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController menuController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController instagramController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController tiktokController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  final TextEditingController cashAppController = TextEditingController();
  final TextEditingController zelleController = TextEditingController();
  final TextEditingController venmoController = TextEditingController();

  final TextEditingController legalNameController = TextEditingController();
  final TextEditingController permitNumberController = TextEditingController();
  final TextEditingController verificationNotesController =
  TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? bannerImage;
  File? idFrontImage;
  File? addressProofImage;

  List<File> galleryImages = [];
  List<Map<String, dynamic>> ownerMenuItems = [];
  List<StoryVideoItem> storyVideos = [];

  bool wantsVerification = false;
  String verificationStatus = 'not_started';

  int get _galleryLimit {
    switch (selectedPlan) {
      case 'pro':
        return 6;
      case 'premium':
        return 10;
      case 'platinum':
        return 15;
      case 'free':
      default:
        return 3;
    }
  }

  int get _storyLimit {
    switch (selectedPlan) {
      case 'pro':
        return 1;
      case 'premium':
      case 'platinum':
        return 5;
      case 'free':
      default:
        return 0;
    }
  }

  int get _menuItemLimit {
    return 25;
  }

  String get _galleryTitle => 'Food Gallery (up to $_galleryLimit photos)';

  String get _storyTitle => 'Story Videos (up to $_storyLimit)';

  String get _menuLimitText {
    if (selectedPlan == 'free') {
      return 'Up to 25 menu items (without cloud menu photos)';
    }
    if (selectedPlan == 'pro') {
      return 'Up to 25 menu items (first 15 can include menu photos)';
    }
    if (selectedPlan == 'premium') {
      return 'Up to 25 menu items (all 25 can include menu photos)';
    }
    return 'All menu features unlocked';
  }

  @override
  void dispose() {
    nameController.dispose();
    cuisineController.dispose();
    addressController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    phoneController.dispose();
    menuController.dispose();
    descriptionController.dispose();

    instagramController.dispose();
    facebookController.dispose();
    tiktokController.dispose();
    youtubeController.dispose();
    whatsappController.dispose();

    cashAppController.dispose();
    zelleController.dispose();
    venmoController.dispose();

    legalNameController.dispose();
    permitNumberController.dispose();
    verificationNotesController.dispose();

    for (final story in storyVideos) {
      story.controller?.dispose();
    }

    super.dispose();
  }

  Future<void> pickBannerImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        bannerImage = File(picked.path);
      });
    }
  }

  void removeBannerImage() {
    setState(() {
      bannerImage = null;
    });
  }

  Future<void> pickGalleryImages() async {
    final int galleryLimit = _galleryLimit;

    if (galleryImages.length >= galleryLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your $selectedPlan plan allows up to $galleryLimit gallery photos',
          ),
        ),
      );
      return;
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 80,
    );

    if (pickedFiles.isEmpty) return;

    setState(() {
      final List<File> newFiles =
      pickedFiles.map((file) => File(file.path)).toList();

      galleryImages = [...galleryImages, ...newFiles].take(galleryLimit).toList();
    });

    if (galleryImages.length >= galleryLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reached $galleryLimit gallery photos for $selectedPlan plan',
          ),
        ),
      );
    }
  }

  void removeImage(int index) {
    setState(() {
      galleryImages.removeAt(index);
    });
  }

  Future<void> addStoryVideo() async {
    final int storyLimit = _storyLimit;

    if (storyVideos.length >= storyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storyLimit == 0
                ? 'Upgrade your plan to add story videos'
                : 'Your $selectedPlan plan allows up to $storyLimit story videos',
          ),
        ),
      );
      return;
    }

    final XFile? pickedVideo =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo == null) return;

    final File file = File(pickedVideo.path);
    final VideoPlayerController controller = VideoPlayerController.file(file);

    await controller.initialize();
    final Duration duration = controller.value.duration;

    if (duration.inSeconds > 30) {
      await controller.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story video must be 30 seconds or less'),
        ),
      );
      return;
    }
    await controller.setLooping(false);

    setState(() {
      storyVideos.add(
        StoryVideoItem(
          file: file,
          controller: controller,
          createdAt: DateTime.now(),
          label: 'Story ${storyVideos.length + 1}',
        ),
      );
    });
  }

  Future<void> replaceStoryVideo(int index) async {
    final XFile? pickedVideo =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo == null) return;

    final File file = File(pickedVideo.path);
    final VideoPlayerController controller = VideoPlayerController.file(file);

    await controller.initialize();
    await controller.setLooping(false);

    final oldController = storyVideos[index].controller;

    setState(() {
      storyVideos[index] = StoryVideoItem(
        file: file,
        controller: controller,
        createdAt: DateTime.now(),
        label: 'Story ${index + 1}',
      );
    });

    await oldController?.dispose();
  }

  Future<void> removeStoryVideo(int index) async {
    final controller = storyVideos[index].controller;

    setState(() {
      storyVideos.removeAt(index);
    });

    await controller?.dispose();

    setState(() {
      for (int i = 0; i < storyVideos.length; i++) {
        storyVideos[i] = storyVideos[i].copyWith(label: 'Story ${i + 1}');
      }
    });
  }

  bool _storyIsActive(DateTime? createdAt) {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inHours < 24;
  }

  void _toggleStoryPlayPause(int index) {
    final controller = storyVideos[index].controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  }

  Future<void> pickIdFrontImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        idFrontImage = File(picked.path);
      });
    }
  }

  Future<void> pickAddressProofImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        addressProofImage = File(picked.path);
      });
    }
  }

  void removeIdFrontImage() {
    setState(() {
      idFrontImage = null;
    });
  }

  void removeAddressProofImage() {
    setState(() {
      addressProofImage = null;
    });
  }

  Future<void> _openMenuEditor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerMenuEditorPage(
          initialMenuItems: ownerMenuItems,
          selectedPlan: selectedPlan,
        ),
      ),
    );

    if (result != null && result is List) {
      setState(() {
        ownerMenuItems = result
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
          ),
        )
            .take(_menuItemLimit)
            .toList();

        menuController.text = ownerMenuItems
            .map((item) => (item['name'] ?? '').toString())
            .where((name) => name.trim().isNotEmpty)
            .join(', ');
      });

      if (result.length > _menuItemLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _menuItemLimit >= 9999
                  ? 'Menu saved successfully'
                  : 'Your $selectedPlan plan allows up to $_menuItemLimit menu items',
            ),
          ),
        );
      }
    }
  }
  Future<void> _pickCurrentLocationForAddress() async {
    try {
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
          const SnackBar(
            content: Text(
              'Location permission permanently denied. Please enable it in phone settings.',
            ),
          ),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String fullAddress = '';

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final String placeName = (place.name ?? '').trim();
        final String street = (place.street ?? '').trim();

        String streetLine = street;
        if (streetLine.isEmpty) {
          streetLine = placeName;
        } else if (placeName.isNotEmpty &&
            !street.toLowerCase().startsWith(placeName.toLowerCase())) {
          streetLine = '$placeName, $street';
        }

        final List<String> parts = [
          streetLine,
          place.locality ?? '',
          place.administrativeArea ?? '',
          place.postalCode ?? '',
          place.country ?? '',
        ].where((part) => part.trim().isNotEmpty).toList();

        fullAddress = parts.join(', ');
      }

      setState(() {
        addressController.text = fullAddress.isNotEmpty
            ? fullAddress
            : '${position.latitude}, ${position.longitude}';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location added to address')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }
  Future<void> _submitForm() async {
    if (nameController.text.trim().isEmpty ||
        cuisineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            businessType == 'food_truck'
                ? 'Please enter truck name and cuisine type'
                : 'Please enter kitchen name and cuisine type',
          ),
        ),
      );
      return;
    }

    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid address'),
        ),
      );
      return;
    }

    if (wantsVerification) {
      if (legalNameController.text.trim().isEmpty ||
          permitNumberController.text.trim().isEmpty ||
          idFrontImage == null ||
          addressProofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all required verification fields and upload both documents',
            ),
          ),
        );
        return;
      }
    }

    double latitude = 37.9577;
    double longitude = -121.2908;

    try {
      final locations = await locationFromAddress(addressController.text.trim());

      if (locations.isNotEmpty) {
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not find exact address. Using default location instead.',
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> storyVideoMaps = storyVideos
        .map(
          (story) => {
        'path': story.file.path,
        'createdAt': story.createdAt?.toIso8601String(),
        'label': story.label,
      },
    )
        .toList();

    final Map<String, dynamic> newBusiness = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': businessType,
      'plan': selectedPlan,
      'isVerified': false,
      'verificationStatus': wantsVerification ? 'pending' : 'not_started',
      'legalName': legalNameController.text.trim(),
      'permitNumber': permitNumberController.text.trim(),
      'verificationNotes': verificationNotesController.text.trim(),
      'idFrontImage': idFrontImage?.path ?? '',
      'addressProofImage': addressProofImage?.path ?? '',
      'title': nameController.text.trim(),
      'cuisine': cuisineController.text.trim(),
      'address': addressController.text.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'openTime': openTimeController.text.trim(),
      'closeTime': closeTimeController.text.trim(),
      'phone': phoneController.text.trim(),
      'whatsapp': whatsappController.text.trim(),
      'cashApp': cashAppController.text.trim(),
      'zelle': zelleController.text.trim(),
      'venmo': venmoController.text.trim(),
      'menu': menuController.text.trim(),
      'menuItems': ownerMenuItems.take(_menuItemLimit).toList(),
      'description': descriptionController.text.trim(),
      'image': bannerImage?.path ?? '',
      'bannerImage': bannerImage?.path ?? '',
      'galleryImages': galleryImages.map((e) => e.path).toList(),
      'storyVideos': storyVideoMaps,
      'storyVideo': storyVideos.isNotEmpty ? storyVideos.first.file.path : '',
      'storyCreatedAt': storyVideos.isNotEmpty
          ? storyVideos.first.createdAt?.toIso8601String()
          : '',
      'instagram': instagramController.text.trim(),
      'facebook': facebookController.text.trim(),
      'tiktok': tiktokController.text.trim(),
      'youtube': youtubeController.text.trim(),
    };

    if (!mounted) return;
    Navigator.pop(context, newBusiness);
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeCard({
    required String value,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final bool isSelected = businessType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            businessType = value;
          });
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: isSelected ? activeColor : Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Menu Setup ($_menuLimitText)'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openMenuEditor,
            icon: const Icon(Icons.restaurant_menu),
            label: Text(
              ownerMenuItems.isEmpty
                  ? 'Add / Edit Menu'
                  : 'Edit Menu (${ownerMenuItems.length} items)',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          icon: Icons.menu_book,
          hintText: 'Selected menu item names will show here',
          controller: menuController,
          maxLines: 3,
          readOnly: true,
        ),
        if (ownerMenuItems.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _menuItemLimit >= 9999
                      ? '${ownerMenuItems.length} menu items added'
                      : '${ownerMenuItems.length}/$_menuItemLimit menu items added',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ownerMenuItems.take(8).map((item) {
                    return Chip(
                      label: Text((item['name'] ?? '').toString()),
                    );
                  }).toList(),
                ),
                if (ownerMenuItems.length > 8) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${ownerMenuItems.length - 8} more items',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Banner Image (Main Cover)'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: pickBannerImage,
              icon: const Icon(Icons.image),
              label: Text(
                bannerImage == null
                    ? 'Select Banner Image'
                    : 'Replace Banner Image',
              ),
            ),
            if (bannerImage != null)
              OutlinedButton.icon(
                onPressed: removeBannerImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Banner'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (bannerImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  bannerImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Banner',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_galleryTitle),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: pickGalleryImages,
          icon: const Icon(Icons.photo_library),
          label: Text('Add Photos (${galleryImages.length}/$_galleryLimit)'),
        ),
        const SizedBox(height: 12),
        if (galleryImages.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: galleryImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(galleryImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(_storyTitle),
        const SizedBox(height: 6),
        Text(
          _storyLimit == 0
              ? 'Free plan does not include customer story videos.'
              : _storyLimit == 1
              ? 'Your current plan allows 1 story video.'
              : 'Owners can add, replace, or delete story videos. Stories stay active for 24 hours.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: addStoryVideo,
          icon: const Icon(Icons.video_library),
          label: Text('Add Story Video (${storyVideos.length}/$_storyLimit)'),
        ),
        const SizedBox(height: 14),
        if (storyVideos.isNotEmpty)
          ListView.separated(
            itemCount: storyVideos.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final story = storyVideos[index];
              final controller = story.controller;
              final bool active = _storyIsActive(story.createdAt);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.orange],
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            story.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            active ? 'Active' : 'Expired',
                            style: TextStyle(
                              color: active
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 210,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: controller != null && controller.value.isInitialized
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: controller.value.size.width,
                                height: controller.value.size.height,
                                child: VideoPlayer(controller),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: IconButton(
                                  onPressed: () =>
                                      _toggleStoryPlayPause(index),
                                  icon: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => replaceStoryVideo(index),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Replace'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => removeStoryVideo(index),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Verification'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            selectedPlan == 'free'
                ? 'Free accounts can unlock in-app ordering and POS after verification approval.'
                : 'Paid accounts can request verification to receive a verified badge.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: wantsVerification,
          onChanged: (value) {
            setState(() {
              wantsVerification = value;
              verificationStatus = value ? 'pending' : 'not_started';
            });
          },
          title: const Text('Apply for verification'),
          subtitle: Text(
            wantsVerification
                ? 'Your verification request will be saved as pending.'
                : 'Turn on to submit verification details',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        if (wantsVerification) ...[
          _buildTextField(
            icon: Icons.badge,
            hintText: 'Legal Full Name',
            controller: legalNameController,
          ),
          _buildTextField(
            icon: Icons.verified_user,
            hintText: 'Permit / License Number',
            controller: permitNumberController,
          ),
          _buildTextField(
            icon: Icons.notes,
            hintText: 'Verification Notes (optional)',
            controller: verificationNotesController,
            maxLines: 3,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: pickIdFrontImage,
                icon: const Icon(Icons.photo_camera_front),
                label: Text(
                  idFrontImage == null ? 'Upload ID Photo' : 'Replace ID Photo',
                ),
              ),
              if (idFrontImage != null)
                OutlinedButton.icon(
                  onPressed: removeIdFrontImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete ID'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (idFrontImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                idFrontImage!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: pickAddressProofImage,
                icon: const Icon(Icons.home_work_outlined),
                label: Text(
                  addressProofImage == null
                      ? 'Upload Address Proof'
                      : 'Replace Address Proof',
                ),
              ),
              if (addressProofImage != null)
                OutlinedButton.icon(
                  onPressed: removeAddressProofImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Proof'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (addressProofImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                addressProofImage!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Verification status: $verificationStatus',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Plan'),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selectedPlan,
          decoration: InputDecoration(
            labelText: 'Choose Plan',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'free',
              child: Text('Free'),
            ),
            DropdownMenuItem(
              value: 'pro',
              child: Text('Pro - \$9.99/month'),
            ),
            DropdownMenuItem(
              value: 'premium',
              child: Text('Premium - \$15.99/month'),
            ),
            DropdownMenuItem(
              value: 'platinum',
              child: Text('Platinum - \$59.99 founding plan'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedPlan = value;

              if (galleryImages.length > _galleryLimit) {
                galleryImages = galleryImages.take(_galleryLimit).toList();
              }

              if (storyVideos.length > _storyLimit) {
                final removedStories = storyVideos.skip(_storyLimit).toList();
                storyVideos = storyVideos.take(_storyLimit).toList();

                for (final story in removedStories) {
                  story.controller?.dispose();
                }

                for (int i = 0; i < storyVideos.length; i++) {
                  storyVideos[i] =
                      storyVideos[i].copyWith(label: 'Story ${i + 1}');
                }
              }

              if (ownerMenuItems.length > _menuItemLimit) {
                ownerMenuItems = ownerMenuItems.take(_menuItemLimit).toList();
                menuController.text = ownerMenuItems
                    .map((item) => (item['name'] ?? '').toString())
                    .where((name) => name.trim().isNotEmpty)
                    .join(', ');
              }
            });
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            selectedPlan == 'free'
                ? 'Free Plan:\n• 1 banner image\n• Up to 3 gallery photos\n• No story videos\n• Up to 25 menu items\n• Menu item photos are not included on cloud\n• Gallery photos are separate from menu items\n• Customers can view menu and contact you\n• In-app ordering & POS locked until verification approval'
                : selectedPlan == 'pro'
                ? 'Pro Plan:\n• 1 banner image\n• Up to 6 gallery photos\n• 1 story video\n• Up to 25 menu items\n• First 15 menu items can include photos\n• Remaining menu items can be added without photos\n• Gallery photos are separate from menu items\n• In-app ordering enabled\n• POS system access'
                : selectedPlan == 'premium'
                ? 'Premium Plan:\n• 1 banner image\n• Up to 10 gallery photos\n• Up to 5 story videos\n• Up to 25 menu items\n• All 25 menu items can include photos\n• Gallery photos are separate from menu items\n• In-app ordering enabled\n• POS system access\n• More visibility & features'
                : 'Platinum Plan:\n• 1 banner image\n• Up to 15 gallery photos\n• Up to 5 story videos\n• All menu features unlocked\n• Gallery photos are separate from menu items\n• In-app ordering & full POS\n• Verified accounts receive a verified badge\n• First 100 food trucks & home kitchens get lifetime flat-fee price lock\n• All future features included',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nameHint =
    businessType == 'food_truck' ? 'Truck Name' : 'Kitchen Name';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Owner Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Business Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBusinessTypeCard(
                  value: 'food_truck',
                  icon: Icons.local_shipping,
                  label: 'Food Truck',
                  activeColor: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildBusinessTypeCard(
                  value: 'home_kitchen',
                  icon: Icons.home,
                  label: 'Home Kitchen',
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              icon: businessType == 'food_truck'
                  ? Icons.local_shipping
                  : Icons.home,
              hintText: nameHint,
              controller: nameController,
            ),
            _buildTextField(
              icon: Icons.restaurant,
              hintText: 'Cuisine Type',
              controller: cuisineController,
            ),
            _buildTextField(
              icon: Icons.location_on,
              hintText: 'Current Location / Address',
              controller: addressController,
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Use current location',
                onPressed: _pickCurrentLocationForAddress,
              ),
            ),
            _buildTextField(
              icon: Icons.access_time,
              hintText: 'Open Time',
              controller: openTimeController,
            ),
            _buildTextField(
              icon: Icons.access_time_filled,
              hintText: 'Close Time',
              controller: closeTimeController,
            ),
            _buildTextField(
              icon: Icons.phone,
              hintText: 'Phone Number',
              controller: phoneController,
            ),
            _buildMenuSection(),
            const SizedBox(height: 16),
            _buildTextField(
              icon: Icons.description,
              hintText: 'Description',
              controller: descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            _buildBannerSection(),
            const SizedBox(height: 20),
            _buildGallerySection(),
            const SizedBox(height: 20),
            _buildStorySection(),
            const SizedBox(height: 20),
            _buildSectionTitle('Social Media Links'),
            const SizedBox(height: 10),
            _buildTextField(
              icon: Icons.camera_alt,
              hintText: 'Instagram username or URL',
              controller: instagramController,
            ),
            _buildTextField(
              icon: Icons.facebook,
              hintText: 'Facebook username or URL',
              controller: facebookController,
            ),
            _buildTextField(
              icon: Icons.music_note,
              hintText: 'TikTok username or URL',
              controller: tiktokController,
            ),
            _buildTextField(
              icon: Icons.play_circle_fill,
              hintText: 'YouTube channel handle or URL',
              controller: youtubeController,
            ),
            _buildTextField(
              icon: Icons.message_rounded,
              hintText: 'WhatsApp number',
              controller: whatsappController,
            ),
            const SizedBox(height: 16),
            _buildPlanSection(),
            const SizedBox(height: 16),
            _buildVerificationSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('Payment Methods (Optional)'),
            const SizedBox(height: 10),
            _buildTextField(
              icon: Icons.attach_money,
              hintText: r'Cash App tag (example: $foodtruck)',
              controller: cashAppController,
            ),
            _buildTextField(
              icon: Icons.account_balance,
              hintText: 'Zelle (phone or email)',
              controller: zelleController,
            ),
            _buildTextField(
              icon: Icons.payments,
              hintText: 'Venmo username',
              controller: venmoController,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Submit Business',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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

class StoryVideoItem {
  final File file;
  final VideoPlayerController? controller;
  final DateTime? createdAt;
  final String label;

  StoryVideoItem({
    required this.file,
    required this.controller,
    required this.createdAt,
    required this.label,
  });

  StoryVideoItem copyWith({
    File? file,
    VideoPlayerController? controller,
    DateTime? createdAt,
    String? label,
  }) {
    return StoryVideoItem(
      file: file ?? this.file,
      controller: controller ?? this.controller,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
    );
  }
}