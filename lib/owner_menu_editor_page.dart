import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OwnerMenuEditorPage extends StatefulWidget {
  final List<dynamic>? initialMenuItems;
  final String selectedPlan;

  const OwnerMenuEditorPage({
    super.key,
    this.initialMenuItems,
    required this.selectedPlan,
  });

  @override
  State<OwnerMenuEditorPage> createState() => _OwnerMenuEditorPageState();
}

class _OwnerMenuEditorPageState extends State<OwnerMenuEditorPage> {
  late List<Map<String, dynamic>> menuItems;
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = const [
    'Main Items',
    'Drinks',
    'Sides',
    'Desserts',
    'Combos',
    'Breakfast',
    'Lunch',
    'Dinner',
  ];

  final List<String> planOptions = const [
    'free',
    'pro',
    'premium',
    'platinum',
  ];

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMenuItems;
    if (initial != null && initial.isNotEmpty) {
      menuItems = initial.map<Map<String, dynamic>>((item) {
        if (item is Map) {
          return _normalizeMenuItem(item);
        }
        return _emptyMenuItem();
      }).toList();
    } else {
      menuItems = [_emptyMenuItem()];
    }
    for (final item in menuItems) {
      item['subscriptionPlan'] = widget.selectedPlan;
    }
  }

  Map<String, dynamic> _emptyMenuItem() {
    return {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': '',
      'price': '',
      'category': 'Main Items',
      'description': '',
      'includedItems': <String>[],
      'removableOptions': <String>[],
      'addOnOptions': <Map<String, dynamic>>[],
      'localImagePath': '',
      'customerImagePath': '',
      'imageUrl': '',
      'isAvailable': true,
      'isFeatured': false,
      'subscriptionPlan': widget.selectedPlan,
      'customerCanSeeImage': false,
      'customerCanSeeStory': false,
    };
  }

  Map<String, dynamic> _normalizeMenuItem(Map item) {
    final String plan = planOptions.contains(item['subscriptionPlan'])
        ? item['subscriptionPlan'].toString()
        : widget.selectedPlan;

    return {
      'id': (item['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      'name': (item['name'] ?? '').toString(),
      'price': (item['price'] ?? '').toString(),
      'category': (item['category'] ?? 'Main Items').toString(),
      'description': (item['description'] ?? '').toString(),
      'includedItems': _normalizeStringList(item['includedItems']),
      'removableOptions': _normalizeStringList(item['removableOptions']),
      'addOnOptions': _normalizeAddOns(item['addOnOptions']),
      'localImagePath': (item['localImagePath'] ?? '').toString(),
      'customerImagePath': (item['customerImagePath'] ?? '').toString(),
      'imageUrl': (item['imageUrl'] ?? '').toString(),
      'isAvailable': item['isAvailable'] is bool ? item['isAvailable'] : true,
      'isFeatured': item['isFeatured'] is bool ? item['isFeatured'] : false,
      'subscriptionPlan': plan,
      'customerCanSeeImage': item['customerCanSeeImage'] is bool
          ? item['customerCanSeeImage']
          : false,
      'customerCanSeeStory': item['customerCanSeeStory'] is bool
          ? item['customerCanSeeStory']
          : false,
    };
  }

  List<String> _normalizeStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> _normalizeAddOns(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map<Map<String, dynamic>>((addOn) {
        return {
          'name': (addOn['name'] ?? '').toString(),
          'price': (addOn['price'] ?? '').toString(),
        };
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  int get _menuItemLimit => 25;

  int get _customerPhotoEnabledCount {
    return menuItems.where((item) => item['customerCanSeeImage'] == true).length;
  }

  int _photoLimitForPlan(String plan) {
    switch (plan) {
      case 'free':
        return 0;
      case 'pro':
        return 15;
      case 'premium':
      case 'platinum':
        return 25;
      default:
        return 0;
    }
  }

  String _planDisplayName(String plan) {
    switch (plan) {
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium';
      case 'platinum':
        return 'Platinum';
      case 'free':
      default:
        return 'Free';
    }
  }

  String _planFeatureText(String plan) {
    switch (plan) {
      case 'free':
        return 'Free: up to 25 menu items. No customer menu photos. Gallery photos are separate.';
      case 'pro':
        return 'Pro: up to 25 menu items. First 15 items can show customer menu photos.';
      case 'premium':
        return 'Premium: up to 25 menu items. All 25 items can show customer menu photos.';
      case 'platinum':
        return 'Platinum: all menu features unlocked. Future upgrades included.';
      default:
        return '';
    }
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'pro':
        return Colors.blue;
      case 'premium':
        return Colors.deepPurple;
      case 'platinum':
        return Colors.orange;
      case 'free':
      default:
        return Colors.green;
    }
  }

  bool _canEnableCustomerImageForIndex(int index) {
    final item = menuItems[index];
    final String plan = item['subscriptionPlan'].toString();
    final int limit = _photoLimitForPlan(plan);

    if (limit == 0) return false;
    if (item['customerCanSeeImage'] == true) return true;

    final int currentCountForPlan = menuItems.where((menuItem) {
      return menuItem['subscriptionPlan'].toString() == plan &&
          menuItem['customerCanSeeImage'] == true;
    }).length;

    return currentCountForPlan < limit;
  }

  Future<void> _pickLocalMenuImage(int index) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() {
      menuItems[index]['localImagePath'] = pickedFile.path;
    });
  }

  Future<void> _pickCustomerMenuImage(int index) async {
    final String plan = menuItems[index]['subscriptionPlan'].toString();

    if (!_canEnableCustomerImageForIndex(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan == 'free'
                ? 'Free plan does not include customer menu photos'
                : 'You reached the customer menu photo limit for the ${_planDisplayName(plan)} plan',
          ),
        ),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() {
      menuItems[index]['customerImagePath'] = pickedFile.path;
      menuItems[index]['customerCanSeeImage'] = true;
      menuItems[index]['imageUrl'] = '';
    });
  }

  void _removeCustomerMenuImage(int index) {
    setState(() {
      menuItems[index]['customerImagePath'] = '';
      menuItems[index]['customerCanSeeImage'] = false;
      menuItems[index]['imageUrl'] = '';
    });
  }

  void _addItem() {
    if (menuItems.length >= _menuItemLimit) return;

    setState(() {
      menuItems.add(_emptyMenuItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      menuItems.removeAt(index);
      if (menuItems.isEmpty) {
        menuItems.add(_emptyMenuItem());
      }
    });
  }

  Future<void> _editStringListField({
    required int index,
    required String title,
    required String fieldKey,
    String helperText = '',
  }) async {
    final controller = TextEditingController(
      text: (menuItems[index][fieldKey] as List<dynamic>)
          .map((e) => e.toString())
          .join(', '),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Use commas between items',
                helperText: helperText.isEmpty ? null : helperText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      menuItems[index][fieldKey] = result
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  Future<void> _editAddOns(int index) async {
    final currentAddOns =
    List<Map<String, dynamic>>.from(menuItems[index]['addOnOptions']);

    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (dialogContext) {
        List<Map<String, dynamic>> tempAddOns = currentAddOns.isEmpty
            ? [
          {'name': '', 'price': ''}
        ]
            : currentAddOns
            .map((e) => {
          'name': (e['name'] ?? '').toString(),
          'price': (e['price'] ?? '').toString(),
        })
            .toList();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Edit Add-ons'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...List.generate(tempAddOns.length, (addOnIndex) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Add-on ${addOnIndex + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (tempAddOns.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          tempAddOns.removeAt(addOnIndex);
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue:
                                tempAddOns[addOnIndex]['name'].toString(),
                                decoration: InputDecoration(
                                  labelText: 'Add-on name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) {
                                  tempAddOns[addOnIndex]['name'] = value;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue:
                                tempAddOns[addOnIndex]['price'].toString(),
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Add-on price',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) {
                                  tempAddOns[addOnIndex]['price'] = value;
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              tempAddOns.add({'name': '', 'price': ''});
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Add-on'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cleaned = tempAddOns.where((e) {
                      final name = e['name'].toString().trim();
                      return name.isNotEmpty;
                    }).map((e) {
                      return {
                        'name': e['name'].toString().trim(),
                        'price': e['price'].toString().trim(),
                      };
                    }).toList();

                    Navigator.pop(dialogContext, cleaned);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      menuItems[index]['addOnOptions'] = result;
    });
  }

  void _saveMenu() {
    final cleaned = menuItems.where((item) {
      final name = item['name'].toString().trim();
      final price = item['price'].toString().trim();
      return name.isNotEmpty && price.isNotEmpty;
    }).map<Map<String, dynamic>>((item) {
      final plan = item['subscriptionPlan'].toString();

      return {
        'id': item['id'].toString(),
        'name': item['name'].toString().trim(),
        'price': double.tryParse(item['price'].toString().trim()) ?? 0.0,
        'category': item['category'].toString().trim().isEmpty
            ? 'Main Items'
            : item['category'].toString().trim(),
        'description': item['description'].toString().trim(),
        'includedItems': _normalizeStringList(item['includedItems']),
        'removableOptions': _normalizeStringList(item['removableOptions']),
        'addOnOptions': _normalizeAddOns(item['addOnOptions']).map((addOn) {
          return {
            'name': addOn['name'].toString().trim(),
            'price': double.tryParse(addOn['price'].toString().trim()) ?? 0.0,
          };
        }).toList(),
        'localImagePath': item['localImagePath'].toString().trim(),
        'customerImagePath': item['customerImagePath'].toString().trim(),
        'imageUrl': item['imageUrl'].toString().trim(),
        'isAvailable': item['isAvailable'] == true,
        'isFeatured': item['isFeatured'] == true,
        'subscriptionPlan': plan,
        'customerCanSeeImage': item['customerCanSeeImage'] == true,
        'customerCanSeeStory': plan == 'premium' || plan == 'platinum'
            ? item['customerCanSeeStory'] == true
            : false,
      };
    }).toList();

    Navigator.pop(context, cleaned);
  }

  Widget _buildSmallInfoChip(
      String label,
      int count, {
        Color? bgColor,
        Color? borderColor,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? Colors.grey.shade300),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final item = menuItems[index];
    final String plan = item['subscriptionPlan'].toString();
    final bool canShowImage = _canEnableCustomerImageForIndex(index);
    final Color planColor = _planColor(plan);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            planColor.withOpacity(0.10),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: planColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: planColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Media & Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: planColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: planColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: planColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plan locked from Owner Portal: ${_planDisplayName(plan)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: planColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _planFeatureText(plan),
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: item['customerCanSeeImage'] == true,
            onChanged: !canShowImage
                ? null
                : (value) {
              setState(() {
                menuItems[index]['customerCanSeeImage'] = value;
                if (!value) {
                  menuItems[index]['customerImagePath'] = '';
                  menuItems[index]['imageUrl'] = '';
                }
              });
            },
            activeColor: planColor,
            contentPadding: EdgeInsets.zero,
            title: const Text('Customer can see menu photo'),
            subtitle: Text(
              plan == 'free'
                  ? 'Free does not include customer menu photos'
                  : plan == 'pro'
                  ? 'Pro allows customer menu photos for first 15 enabled items'
                  : plan == 'premium'
                  ? 'Premium allows customer menu photos for all 25 items'
                  : 'Platinum unlocks all customer menu media',
            ),
          ),
          SwitchListTile(
            value: item['customerCanSeeStory'] == true,
            onChanged: plan == 'premium' || plan == 'platinum'
                ? (value) {
              setState(() {
                menuItems[index]['customerCanSeeStory'] = value;
              });
            }
                : null,
            activeColor: planColor,
            contentPadding: EdgeInsets.zero,
            title: const Text('Customer can see story-linked media'),
            subtitle: Text(
              plan == 'premium' || plan == 'platinum'
                  ? 'Available for Premium and Platinum'
                  : 'Story-linked media is Premium or higher',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({
    required String path,
    required double height,
    required String emptyText,
  }) {
    if (path.isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Text(
            emptyText,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        image: DecorationImage(
          image: FileImage(File(path)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMenuCard(int index) {
    final item = menuItems[index];
    final String plan = item['subscriptionPlan'].toString();
    final Color planColor = _planColor(plan);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: planColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: planColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: planColor.withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: planColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Menu Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (menuItems.length > 1)
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item['name'].toString(),
            decoration: InputDecoration(
              labelText: 'Item name',
              filled: true,
              fillColor: Colors.orange.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) {
              menuItems[index]['name'] = value;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item['price'].toString(),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                    filled: true,
                    fillColor: Colors.green.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) {
                    menuItems[index]['price'] = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: categories.contains(item['category'])
                      ? item['category']
                      : 'Main Items',
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    menuItems[index]['category'] = value ?? 'Main Items';
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item['description'].toString(),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Example: comes with rice, beans, salsa, cheese',
              filled: true,
              fillColor: Colors.purple.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) {
              menuItems[index]['description'] = value;
            },
          ),
          const SizedBox(height: 14),
          _buildSectionHeader(
            icon: Icons.point_of_sale,
            title: 'Owner / POS Local Menu Photo',
            color: Colors.teal,
          ),
          const SizedBox(height: 10),
          _buildImagePreview(
            path: item['localImagePath'].toString(),
            height: 170,
            emptyText: 'No local POS photo selected',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickLocalMenuImage(index),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pick Local Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item['localImagePath'].toString().isEmpty
                      ? null
                      : () {
                    setState(() {
                      menuItems[index]['localImagePath'] = '';
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This local photo is for owner device / POS use. Gallery photos are separate from menu items.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          _buildSectionHeader(
            icon: Icons.image_outlined,
            title: 'Customer Menu Photo',
            color: planColor,
          ),
          const SizedBox(height: 10),
          _buildImagePreview(
            path: item['customerImagePath'].toString(),
            height: 170,
            emptyText: item['customerCanSeeImage'] == true
                ? 'No customer menu photo selected'
                : 'Enable customer menu photo in the plan section below',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: item['customerCanSeeImage'] == true
                      ? () => _pickCustomerMenuImage(index)
                      : null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload Customer Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item['customerImagePath'].toString().isEmpty
                      ? null
                      : () => _removeCustomerMenuImage(index),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This works as a local customer-photo placeholder for now. Later you can connect this same button to Firebase Storage.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallInfoChip(
                'Included',
                (item['includedItems'] as List).length,
                bgColor: Colors.orange.shade50,
                borderColor: Colors.orange.shade200,
              ),
              _buildSmallInfoChip(
                'Remove options',
                (item['removableOptions'] as List).length,
                bgColor: Colors.red.shade50,
                borderColor: Colors.red.shade200,
              ),
              _buildSmallInfoChip(
                'Add-ons',
                (item['addOnOptions'] as List).length,
                bgColor: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editStringListField(
                    index: index,
                    title: 'Included Items',
                    fieldKey: 'includedItems',
                    helperText: 'Example: Rice, Beans, Salsa',
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Included'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade900,
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editStringListField(
                    index: index,
                    title: 'Removable Options',
                    fieldKey: 'removableOptions',
                    helperText: 'Example: Onion, Tomato, Cilantro',
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Removals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
              onPressed: () => _editAddOns(index),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Edit Add-ons'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade900,
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: item['isAvailable'] == true,
            onChanged: (value) {
              setState(() {
                menuItems[index]['isAvailable'] = value;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
            title: const Text('Available today'),
          ),
          SwitchListTile(
            value: item['isFeatured'] == true,
            onChanged: (value) {
              setState(() {
                menuItems[index]['isFeatured'] = value;
              });
            },
            activeColor: Colors.deepOrange,
            contentPadding: EdgeInsets.zero,
            title: const Text('Featured item'),
          ),
          const SizedBox(height: 10),
          _buildPlanCard(index),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _menuItemLimit - menuItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Edit Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade100,
                  Colors.deepOrange.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Setup Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menu items: up to 25 total. Remaining: $remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gallery photos are separate from menu items. Free can add up to 25 menu items without customer menu photos. Pro allows customer menu photos for first 15 items. Premium allows customer menu photos for all 25 items. Platinum unlocks all menu features.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer menu-photo enabled right now: $_customerPhotoEnabledCount',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) => _buildMenuCard(index),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: menuItems.length >= _menuItemLimit ? null : _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Menu Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveMenu,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}