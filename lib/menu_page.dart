import 'dart:io';

import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  final Map<String, dynamic> truck;
  final bool isOwnerView;
  final bool isDarkMode;

  const MenuPage({
    super.key,
    required this.truck,
    this.isOwnerView = false,
    this.isDarkMode = false,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Map<String, int> cart = {};

  bool get _isDarkMode => widget.isDarkMode;
  Color get _pageBg => _isDarkMode ? Colors.black : const Color(0xFFFFF7FC);
  Color get _cardBg => _isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
  Color get _primaryText => _isDarkMode ? Colors.white : Colors.black87;
  Color get _secondaryText =>
      _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
  Color get _borderColor =>
      _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

  List<Map<String, dynamic>> get menuItems {
    final dynamic rawMenuItems = widget.truck['menuItems'];

    if (rawMenuItems is List && rawMenuItems.isNotEmpty) {
      return rawMenuItems
          .map<Map<String, dynamic>>((item) {
        if (item is Map) {
          return {
            'id': (item['id'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
            'price': _toDouble(item['price']),
            'category': (item['category'] ?? 'Main Items').toString(),
            'description': (item['description'] ?? '').toString(),
            'includedItems': _toStringList(item['includedItems']),
            'removableOptions': _toStringList(item['removableOptions']),
            'addOnOptions': _toAddOnList(item['addOnOptions']),
            'localImagePath': (item['localImagePath'] ?? '').toString(),
            'customerImagePath':
            (item['customerImagePath'] ?? '').toString(),
            'imageUrl': (item['imageUrl'] ?? '').toString(),
            'isAvailable':
            item['isAvailable'] is bool ? item['isAvailable'] : true,
            'isFeatured':
            item['isFeatured'] is bool ? item['isFeatured'] : false,
            'subscriptionPlan':
            (item['subscriptionPlan'] ?? 'free').toString(),
            'customerCanSeeImage': item['customerCanSeeImage'] is bool
                ? item['customerCanSeeImage']
                : false,
            'customerCanSeeStory': item['customerCanSeeStory'] is bool
                ? item['customerCanSeeStory']
                : false,
          };
        }

        return {
          'id': '',
          'name': item.toString(),
          'price': 0.0,
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
          'subscriptionPlan': 'free',
          'customerCanSeeImage': false,
          'customerCanSeeStory': false,
        };
      })
          .where((item) => item['name'].toString().trim().isNotEmpty)
          .toList();
    }

    return [
      {
        'id': 'sample_1',
        'name': 'Chicken Tacos',
        'price': 3.99,
        'category': 'Main Items',
        'description': 'Fresh tacos with salsa and house seasoning.',
        'includedItems': <String>['Salsa'],
        'removableOptions': <String>['Onion', 'Tomato'],
        'addOnOptions': <Map<String, dynamic>>[
          {'name': 'Extra Cheese', 'price': 1.0},
        ],
        'localImagePath': '',
        'customerImagePath': '',
        'imageUrl': '',
        'isAvailable': true,
        'isFeatured': false,
        'subscriptionPlan': 'free',
        'customerCanSeeImage': false,
        'customerCanSeeStory': false,
      },
      {
        'id': 'sample_2',
        'name': 'Mango Lassi',
        'price': 4.99,
        'category': 'Drinks',
        'description': 'Cold mango yogurt drink.',
        'includedItems': <String>[],
        'removableOptions': <String>[],
        'addOnOptions': <Map<String, dynamic>>[],
        'localImagePath': '',
        'customerImagePath': '',
        'imageUrl': '',
        'isAvailable': true,
        'isFeatured': false,
        'subscriptionPlan': 'free',
        'customerCanSeeImage': false,
        'customerCanSeeStory': false,
      },
    ];
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> _toAddOnList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map<Map<String, dynamic>>((addOn) {
        return {
          'name': (addOn['name'] ?? '').toString(),
          'price': _toDouble(addOn['price']),
        };
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  int _ownerGridColumnCount(BuildContext context) {
    if (!widget.isOwnerView) return 1;

    final media = MediaQuery.of(context);
    final bool isLandscape = media.orientation == Orientation.landscape;
    final double width = media.size.width;

    if (!isLandscape) return 1;
    if (width >= 900) return 3;
    return 2;
  }

  bool _useOwnerCompactCards(BuildContext context) {
    return widget.isOwnerView && _ownerGridColumnCount(context) > 1;
  }

  double _calculateCustomItemTotal(
      double basePrice,
      List<Map<String, dynamic>> selectedAddOns,
      int quantity,
      ) {
    double addOnTotal = 0;
    for (final addOn in selectedAddOns) {
      addOnTotal += _toDouble(addOn['price']);
    }
    return (basePrice + addOnTotal) * quantity;
  }

  String _buildCartKey({
    required String itemName,
    required List<String> removedOptions,
    required List<Map<String, dynamic>> selectedAddOns,
    required String notes,
  }) {
    final removed = [...removedOptions]..sort();
    final addOns = selectedAddOns
        .map((e) => '${e['name']}|${_toDouble(e['price'])}')
        .toList()
      ..sort();

    return '${itemName}__removed:${removed.join(",")}__addons:${addOns.join(",")}__notes:${notes.trim()}';
  }

  String _buildCartDisplayName({
    required String itemName,
    required List<String> removedOptions,
    required List<Map<String, dynamic>> selectedAddOns,
  }) {
    final parts = <String>[itemName];

    if (removedOptions.isNotEmpty) {
      parts.add('No ${removedOptions.join(", ")}');
    }

    if (selectedAddOns.isNotEmpty) {
      parts.add(
        '+ ${selectedAddOns.map((e) => e['name'].toString()).join(", ")}',
      );
    }

    return parts.join(' • ');
  }

  Future<void> _showCustomizeItemDialog(Map<String, dynamic> item) async {
    final String itemName = item['name'].toString();
    final double basePrice = item['price'] as double;
    final List<String> removableOptions =
    (item['removableOptions'] as List).map((e) => e.toString()).toList();
    final List<Map<String, dynamic>> addOns =
    (item['addOnOptions'] as List).cast<Map<String, dynamic>>();

    final Set<String> removedOptions = {};
    final List<Map<String, dynamic>> selectedAddOns = [];
    final TextEditingController notesController = TextEditingController();
    int quantity = 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double totalPrice = _calculateCustomItemTotal(
              basePrice,
              selectedAddOns,
              quantity,
            );

            return AlertDialog(
              title: Text(itemName),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base price: \$${basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (removableOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Remove items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...removableOptions.map((option) {
                        return CheckboxListTile(
                          value: removedOptions.contains(option),
                          contentPadding: EdgeInsets.zero,
                          title: Text('No $option'),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                removedOptions.add(option);
                              } else {
                                removedOptions.remove(option);
                              }
                            });
                          },
                        );
                      }),
                    ],
                    if (addOns.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Add-ons',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...addOns.map((addOn) {
                        final String addOnName =
                        (addOn['name'] ?? '').toString();
                        final double addOnPrice = _toDouble(addOn['price']);
                        final bool isSelected = selectedAddOns.any(
                              (selected) => selected['name'] == addOnName,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '$addOnName (+\$${addOnPrice.toStringAsFixed(2)})',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedAddOns.add({
                                  'name': addOnName,
                                  'price': addOnPrice,
                                });
                              } else {
                                selectedAddOns.removeWhere(
                                      (selected) =>
                                  selected['name'] == addOnName,
                                );
                              }
                            });
                          },
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Special instructions',
                        hintText: 'Example: extra spicy, sauce on side',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: quantity > 1
                              ? () {
                            setDialogState(() {
                              quantity--;
                            });
                          }
                              : null,
                          icon: const Icon(Icons.remove_circle),
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              quantity++;
                            });
                          },
                          icon: const Icon(Icons.add_circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final removedList = removedOptions.toList();
                    final notes = notesController.text.trim();

                    final cartKey = _buildCartKey(
                      itemName: itemName,
                      removedOptions: removedList,
                      selectedAddOns: selectedAddOns,
                      notes: notes,
                    );

                    final displayName = _buildCartDisplayName(
                      itemName: itemName,
                      removedOptions: removedList,
                      selectedAddOns: selectedAddOns,
                    );

                    setState(() {
                      cart[cartKey] = (cart[cartKey] ?? 0) + quantity;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$displayName added to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addItem(String name) {
    setState(() {
      cart[name] = (cart[name] ?? 0) + 1;
    });
  }

  void removeItem(String name) {
    final String? keyToRemove = cart.keys.cast<String?>().firstWhere(
          (key) => key != null && key.split('__').first == name,
      orElse: () => null,
    );

    if (keyToRemove == null) return;

    setState(() {
      if (cart[keyToRemove]! > 1) {
        cart[keyToRemove] = cart[keyToRemove]! - 1;
      } else {
        cart.remove(keyToRemove);
      }
    });
  }

  int _quantityForItem(String name) {
    int qty = 0;
    for (final entry in cart.entries) {
      if (entry.key.split('__').first == name) {
        qty += entry.value;
      }
    }
    return qty;
  }

  double get total {
    double sum = 0;

    for (final entry in cart.entries) {
      final String cartKey = entry.key;
      final int quantity = entry.value;

      final parts = cartKey.split('__');
      final String itemName = parts.isNotEmpty ? parts[0] : '';

      final Map<String, dynamic>? matchedItem =
      menuItems.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item != null && item['name'].toString() == itemName,
        orElse: () => null,
      );

      final double basePrice =
      matchedItem != null ? _toDouble(matchedItem['price']) : 0.0;

      List<Map<String, dynamic>> selectedAddOns = [];

      for (final part in parts.skip(1)) {
        if (part.startsWith('addons:')) {
          final addOnText = part.replaceFirst('addons:', '');
          if (addOnText.trim().isNotEmpty) {
            selectedAddOns = addOnText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .map((e) {
              final addOnParts = e.split('|');
              return {
                'name': addOnParts.isNotEmpty ? addOnParts[0] : '',
                'price':
                addOnParts.length > 1 ? _toDouble(addOnParts[1]) : 0.0,
              };
            }).toList();
          }
        }
      }

      sum += _calculateCustomItemTotal(
        basePrice,
        selectedAddOns,
        quantity,
      );
    }

    return sum;
  }

  Map<String, List<Map<String, dynamic>>> get groupedMenu {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in menuItems) {
      if (item['isAvailable'] != true) continue;

      final String category = (item['category'] ?? 'Main Items').toString();
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return grouped;
  }

  int get totalItemsSelected {
    int count = 0;
    for (final qty in cart.values) {
      count += qty;
    }
    return count;
  }

  Widget _buildChip(String text, {IconData? icon, bool compact = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: _primaryText),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
          color: _primaryText,
        ),
      ),
    );
  }

  void _openFullScreenImage(String path, {bool isNetwork = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: isNetwork
                  ? Image.network(path, fit: BoxFit.contain)
                  : Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(
      Map<String, dynamic> item, {
        bool compact = false,
      }) {
    final String localImagePath = item['localImagePath'].toString().trim();
    final String customerImagePath =
    (item['customerImagePath'] ?? '').toString().trim();
    final String imageUrl = item['imageUrl'].toString().trim();
    final bool customerCanSeeImage = item['customerCanSeeImage'] == true;

    final String displayPath = widget.isOwnerView
        ? localImagePath
        : (customerCanSeeImage && customerImagePath.isNotEmpty
        ? customerImagePath
        : localImagePath);

    final double imageSize = compact ? 78 : 110;

    final bool hasFileImage =
        displayPath.isNotEmpty && File(displayPath).existsSync();
    final bool hasCloudImage = customerCanSeeImage && imageUrl.isNotEmpty;

    if (!hasFileImage && !hasCloudImage) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.orange.shade900.withOpacity(0.3)
              : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Icon(Icons.restaurant_menu, size: compact ? 28 : 34),
      );
    }

    if (hasFileImage) {
      return GestureDetector(
        onTap: () => _openFullScreenImage(displayPath),
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(displayPath),
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Icon(Icons.broken_image_outlined),
                );
              },
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(imageUrl, isNetwork: true),
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return const Center(
                child: Icon(Icons.broken_image_outlined),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
      Map<String, dynamic> item, {
        bool compact = false,
      }) {
    final String name = item['name'].toString();
    final double price = item['price'] as double;
    final int qty = _quantityForItem(name);
    final String description = item['description'].toString().trim();
    final List<String> includedItems =
    (item['includedItems'] as List).map((e) => e.toString()).toList();
    final List<String> removableOptions =
    (item['removableOptions'] as List).map((e) => e.toString()).toList();
    final List<Map<String, dynamic>> addOns =
    (item['addOnOptions'] as List).cast<Map<String, dynamic>>();
    final bool isFeatured = item['isFeatured'] == true;
    final String subscriptionPlan = item['subscriptionPlan'].toString();

    return Container(
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: compact
          ? _buildCompactItemCardBody(
        item: item,
        name: name,
        price: price,
        qty: qty,
        description: description,
        includedItems: includedItems,
        removableOptions: removableOptions,
        addOns: addOns,
        isFeatured: isFeatured,
        subscriptionPlan: subscriptionPlan,
      )
          : _buildNormalItemCardBody(
        item: item,
        name: name,
        price: price,
        qty: qty,
        description: description,
        includedItems: includedItems,
        removableOptions: removableOptions,
        addOns: addOns,
        isFeatured: isFeatured,
        subscriptionPlan: subscriptionPlan,
      ),
    );
  }

  Widget _buildNormalItemCardBody({
    required Map<String, dynamic> item,
    required String name,
    required double price,
    required int qty,
    required String description,
    required List<String> includedItems,
    required List<String> removableOptions,
    required List<Map<String, dynamic>> addOns,
    required bool isFeatured,
    required String subscriptionPlan,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(item),
            const SizedBox(width: 12),
            Expanded(
              child: _buildItemTextArea(
                name: name,
                price: price,
                description: description,
                isFeatured: isFeatured,
                subscriptionPlan: subscriptionPlan,
              ),
            ),
          ],
        ),
        _buildOptionsArea(
          includedItems: includedItems,
          removableOptions: removableOptions,
          addOns: addOns,
        ),
        _buildQtyRow(name: name, qty: qty),
      ],
    );
  }

  Widget _buildCompactItemCardBody({
    required Map<String, dynamic> item,
    required String name,
    required double price,
    required int qty,
    required String description,
    required List<String> includedItems,
    required List<String> removableOptions,
    required List<Map<String, dynamic>> addOns,
    required bool isFeatured,
    required String subscriptionPlan,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(item, compact: true),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemTextArea(
                name: name,
                price: price,
                description: description,
                isFeatured: isFeatured,
                subscriptionPlan: subscriptionPlan,
                compact: true,
              ),
            ),
          ],
        ),
        _buildOptionsArea(
          includedItems: includedItems,
          removableOptions: removableOptions,
          addOns: addOns,
          compact: true,
        ),
        _buildQtyRow(name: name, qty: qty, compact: true),
      ],
    );
  }

  Widget _buildItemTextArea({
    required String name,
    required double price,
    required String description,
    required bool isFeatured,
    required String subscriptionPlan,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (isFeatured)
              _buildChip('Featured', icon: Icons.star_border, compact: compact),
            if (subscriptionPlan != 'free')
              _buildChip(
                subscriptionPlan == 'pro' ? 'Pro' : 'Premium',
                icon: Icons.workspace_premium_outlined,
                compact: compact,
              ),
          ],
        ),
        if (isFeatured || subscriptionPlan != 'free')
          SizedBox(height: compact ? 4 : 6),
        Text(
          name,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
          style: TextStyle(
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w800,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            color: _secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            description,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              color: _secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsArea({
    required List<String> includedItems,
    required List<String> removableOptions,
    required List<Map<String, dynamic>> addOns,
    bool compact = false,
  }) {
    if (includedItems.isEmpty && removableOptions.isEmpty && addOns.isEmpty) {
      return const SizedBox(height: 12);
    }

    return Column(
      children: [
        SizedBox(height: compact ? 9 : 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (includedItems.isNotEmpty) ...[
                _buildSectionLabel('Included', compact: compact),
                Wrap(
                  children: includedItems
                      .map(
                        (e) => _buildChip(
                      e,
                      icon: Icons.check_circle_outline,
                      compact: compact,
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],
              if (removableOptions.isNotEmpty) ...[
                _buildSectionLabel('Can remove', compact: compact),
                Wrap(
                  children: removableOptions
                      .map(
                        (e) => _buildChip(
                      e,
                      icon: Icons.remove_circle_outline,
                      compact: compact,
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],
              if (addOns.isNotEmpty) ...[
                _buildSectionLabel('Add-ons', compact: compact),
                Wrap(
                  children: addOns.map((addOn) {
                    final String addOnName =
                    (addOn['name'] ?? '').toString();
                    final double addOnPrice = _toDouble(addOn['price']);
                    return _buildChip(
                      '$addOnName (+\$${addOnPrice.toStringAsFixed(2)})',
                      icon: Icons.add_circle_outline,
                      compact: compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyRow({
    required String name,
    required int qty,
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              qty > 0 ? 'Added: $qty' : 'Tap + to add item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: _secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
                onPressed: () => removeItem(name),
                icon: Icon(
                  Icons.remove_circle,
                  color: _isDarkMode ? Colors.orange : Colors.black,
                ),
              ),
              Text(
                qty.toString(),
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
              IconButton(
                visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
                onPressed: () {
                  final item = menuItems.firstWhere(
                        (menuItem) => menuItem['name'].toString() == name,
                  );
                  _showCustomizeItemDialog(item);
                },
                icon: Icon(
                  Icons.add_circle,
                  color: _isDarkMode ? Colors.orange : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections({
    required Map<String, List<Map<String, dynamic>>> grouped,
    required int columnCount,
    required bool compact,
  }) {
    return grouped.entries.map((entry) {
      final String category = entry.key;
      final List<Map<String, dynamic>> items = entry.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              compact ? 12 : 14,
              compact ? 12 : 16,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: compact ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: _primaryText,
                    ),
                  ),
                ),
                if (compact)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$columnCount columns',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (columnCount == 1)
            ...items.map((item) => _buildItemCard(item, compact: false))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: columnCount == 3 ? 1.12 : 1.35,
                ),
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index], compact: true);
                },
              ),
            ),
        ],
      );
    }).toList();
  }

  List<Map<String, dynamic>> _buildOrderItemsForReturn() {
    final List<Map<String, dynamic>> orderItems = [];

    for (final entry in cart.entries) {
      final String cartKey = entry.key;
      final int quantity = entry.value;

      final parts = cartKey.split('__');
      final String itemName = parts.isNotEmpty ? parts[0] : '';

      final Map<String, dynamic>? matchedItem =
      menuItems.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item != null && item['name'].toString() == itemName,
        orElse: () => null,
      );

      final double basePrice =
      matchedItem != null ? _toDouble(matchedItem['price']) : 0.0;

      List<String> removedOptions = [];
      List<Map<String, dynamic>> selectedAddOns = [];
      String notes = '';

      for (final part in parts.skip(1)) {
        if (part.startsWith('removed:')) {
          final removedText = part.replaceFirst('removed:', '');
          if (removedText.trim().isNotEmpty) {
            removedOptions = removedText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } else if (part.startsWith('addons:')) {
          final addOnText = part.replaceFirst('addons:', '');
          if (addOnText.trim().isNotEmpty) {
            selectedAddOns = addOnText
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .map((e) {
              final addOnParts = e.split('|');
              return {
                'name': addOnParts.isNotEmpty ? addOnParts[0] : '',
                'price':
                addOnParts.length > 1 ? _toDouble(addOnParts[1]) : 0.0,
              };
            }).toList();
          }
        } else if (part.startsWith('notes:')) {
          notes = part.replaceFirst('notes:', '').trim();
        }
      }

      final double itemTotal = _calculateCustomItemTotal(
        basePrice,
        selectedAddOns,
        quantity,
      );

      orderItems.add({
        'cartKey': cartKey,
        'name': itemName,
        'quantity': quantity,
        'basePrice': basePrice,
        'removedOptions': removedOptions,
        'selectedAddOns': selectedAddOns,
        'notes': notes,
        'totalPrice': itemTotal,
      });
    }

    return orderItems;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedMenu;
    final int columnCount = _ownerGridColumnCount(context);
    final bool compact = _useOwnerCompactCards(context);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _primaryText,
        elevation: 0,
        title: Text(widget.truck['title'] ?? 'Menu'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              widget.isOwnerView
                  ? 'Owner POS menu. Rotate your phone/tablet for 2–3 item grid view.'
                  : 'Menu details, item options, and photos are ready here.',
              style: TextStyle(
                fontSize: 14,
                color: _secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? Center(
              child: Text(
                'No available menu items yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: _secondaryText,
                ),
              ),
            )
                : ListView(
              padding: const EdgeInsets.only(bottom: 10),
              children: _buildCategorySections(
                grouped: grouped,
                columnCount: columnCount,
                compact: compact,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey.shade900 : Colors.orange.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? Colors.grey.shade700 : Colors.orange.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Items',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      totalItemsSelected.toString(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: total == 0
                        ? null
                        : () {
                      Navigator.pop(context, {
                        'cart': cart,
                        'orderItems': _buildOrderItemsForReturn(),
                        'total': total,
                      });
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Add to Order'),
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