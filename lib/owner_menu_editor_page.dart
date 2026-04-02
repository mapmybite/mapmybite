import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class OwnerMenuEditorPage extends StatefulWidget {
  final List<dynamic>? initialMenuItems;

  const OwnerMenuEditorPage({
    super.key,
    this.initialMenuItems,
  });

  @override
  State<OwnerMenuEditorPage> createState() => _OwnerMenuEditorPageState();
}

class _OwnerMenuEditorPageState extends State<OwnerMenuEditorPage> {
  late List<Map<String, dynamic>> menuItems;
  final ImagePicker _picker = ImagePicker();
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
      'imageUrl': '',
      'isAvailable': true,
      'isFeatured': false,
      'subscriptionPlan': 'free',
      'customerCanSeeImage': false,
      'customerCanSeeStory': false,
    };
  }

  Map<String, dynamic> _normalizeMenuItem(Map item) {
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
      'imageUrl': (item['imageUrl'] ?? '').toString(),
      'isAvailable': item['isAvailable'] is bool ? item['isAvailable'] : true,
      'isFeatured': item['isFeatured'] is bool ? item['isFeatured'] : false,
      'subscriptionPlan': planOptions.contains(item['subscriptionPlan'])
          ? item['subscriptionPlan'].toString()
          : 'free',
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

  void _addItem() {
    if (menuItems.length >= 25) return;

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
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Use commas between items',
                helperText: helperText.isEmpty ? null : helperText,
                border: const OutlineInputBorder(),
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
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
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
                                decoration: const InputDecoration(
                                  labelText: 'Add-on name',
                                  border: OutlineInputBorder(),
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
                                decoration: const InputDecoration(
                                  labelText: 'Add-on price',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(),
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
            'price':
            double.tryParse(addOn['price'].toString().trim()) ?? 0.0,
          };
        }).toList(),
        'localImagePath': item['localImagePath'].toString().trim(),
        'imageUrl': item['imageUrl'].toString().trim(),
        'isAvailable': item['isAvailable'] == true,
        'isFeatured': item['isFeatured'] == true,
        'subscriptionPlan': plan,
        'customerCanSeeImage': plan == 'free'
            ? false
            : item['customerCanSeeImage'] == true,
        'customerCanSeeStory': plan == 'premium'
            ? item['customerCanSeeStory'] == true
            : false,
      };
    }).toList();

    Navigator.pop(context, cleaned);
  }

  Widget _buildSmallInfoChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
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

  Widget _buildPlanCard(int index) {
    final item = menuItems[index];
    final plan = item['subscriptionPlan'].toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Media & Subscription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: planOptions.contains(plan) ? plan : 'free',
            decoration: InputDecoration(
              labelText: 'Plan for this item',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: planOptions.map((planName) {
              return DropdownMenuItem<String>(
                value: planName,
                child: Text(
                  planName == 'free'
                      ? 'Free'
                      : planName == 'pro'
                      ? 'Pro'
                      : 'Premium',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                final selected = value ?? 'free';
                menuItems[index]['subscriptionPlan'] = selected;

                if (selected == 'free') {
                  menuItems[index]['customerCanSeeImage'] = false;
                  menuItems[index]['customerCanSeeStory'] = false;
                } else if (selected == 'pro') {
                  menuItems[index]['customerCanSeeImage'] = true;
                  menuItems[index]['customerCanSeeStory'] = false;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: item['customerCanSeeImage'] == true,
            onChanged: plan == 'free'
                ? null
                : (value) {
              setState(() {
                menuItems[index]['customerCanSeeImage'] = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Customer can see food photo'),
            subtitle: Text(
              plan == 'free'
                  ? 'Upgrade to Pro or Premium later for customer-side photos'
                  : 'Owner still keeps local photo on device too',
            ),
          ),
          SwitchListTile(
            value: item['customerCanSeeStory'] == true,
            onChanged: plan == 'premium'
                ? (value) {
              setState(() {
                menuItems[index]['customerCanSeeStory'] = value;
              });
            }
                : null,
            contentPadding: EdgeInsets.zero,
            title: const Text('Customer can see story media'),
            subtitle: Text(
              plan == 'premium'
                  ? 'Premium can unlock story/video visibility later'
                  : 'Story visibility is reserved for Premium setup',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(int index) {
    final item = menuItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
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
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item['name'].toString(),
            decoration: InputDecoration(
              labelText: 'Item name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              menuItems[index]['description'] = value;
            },
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Owner-side local menu photo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (item['localImagePath'].toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: DecorationImage(
                      image: FileImage(File(item['localImagePath'].toString())),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: const Center(
                    child: Text('No local photo selected'),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickLocalMenuImage(index),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pick Local Photo'),
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
                      label: const Text('Remove Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'This photo is for owner device/POS use. Customers will only see cloud photos later if enabled.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item['imageUrl'].toString(),
            decoration: InputDecoration(
              labelText: 'Customer image URL (future cloud photo)',
              hintText: 'Leave blank for now',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText:
              'Use later for subscribed owners when cloud media is added',
            ),
            onChanged: (value) {
              menuItems[index]['imageUrl'] = value;
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallInfoChip(
                'Included',
                (item['includedItems'] as List).length,
              ),
              _buildSmallInfoChip(
                'Remove options',
                (item['removableOptions'] as List).length,
              ),
              _buildSmallInfoChip(
                'Add-ons',
                (item['addOnOptions'] as List).length,
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
    final remaining = 25 - menuItems.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner can add up to 25 items. Remaining: $remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Free plan can still save full menu details. Local image path is for owner-side device use later. Customer-side media fields are already ready for future subscription logic.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
                  child: OutlinedButton.icon(
                    onPressed: menuItems.length >= 25 ? null : _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Menu Item'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveMenu,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Menu'),
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