import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  final Map<String, dynamic> truck;

  const MenuPage({super.key, required this.truck});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Map<String, int> cart = {};

  List<Map<String, dynamic>> get menuItems {
    final dynamic rawMenuItems = widget.truck['menuItems'];

    if (rawMenuItems is List && rawMenuItems.isNotEmpty) {
      return rawMenuItems.map<Map<String, dynamic>>((item) {
        if (item is Map) {
          return {
            'name': (item['name'] ?? '').toString(),
            'price': _toDouble(item['price']),
            'category': (item['category'] ?? 'Main Items').toString(),
          };
        }

        return {
          'name': item.toString(),
          'price': 0.0,
          'category': 'Main Items',
        };
      }).where((item) => item['name'].toString().trim().isNotEmpty).toList();
    }

    return [
      {'name': 'Chicken Tacos', 'price': 3.99, 'category': 'Main Items'},
      {'name': 'Beef Tacos', 'price': 4.49, 'category': 'Main Items'},
      {'name': 'Fish Tacos', 'price': 4.99, 'category': 'Main Items'},
      {'name': 'Shrimp Tacos', 'price': 5.49, 'category': 'Main Items'},
      {'name': 'Veggie Tacos', 'price': 3.49, 'category': 'Main Items'},
      {'name': 'Bean Burrito', 'price': 7.49, 'category': 'Main Items'},
      {'name': 'Chicken Burrito', 'price': 8.99, 'category': 'Main Items'},
      {'name': 'Beef Burrito', 'price': 9.49, 'category': 'Main Items'},
      {'name': 'Steak Burrito', 'price': 10.49, 'category': 'Main Items'},
      {'name': 'Veg Quesadilla', 'price': 7.49, 'category': 'Main Items'},
      {'name': 'Chicken Quesadilla', 'price': 8.49, 'category': 'Main Items'},
      {'name': 'Paneer Wrap', 'price': 8.49, 'category': 'Main Items'},
      {'name': 'Chicken Wrap', 'price': 8.99, 'category': 'Main Items'},
      {'name': 'Loaded Nachos', 'price': 6.99, 'category': 'Main Items'},
      {'name': 'Cheese Nachos', 'price': 5.99, 'category': 'Main Items'},
      {'name': 'Rice Bowl', 'price': 9.99, 'category': 'Main Items'},
      {'name': 'Chicken Rice Bowl', 'price': 10.49, 'category': 'Main Items'},
      {'name': 'Paneer Rice Bowl', 'price': 9.99, 'category': 'Main Items'},

      {'name': 'Fries', 'price': 3.49, 'category': 'Sides'},
      {'name': 'Loaded Fries', 'price': 4.99, 'category': 'Sides'},
      {'name': 'Chips & Salsa', 'price': 2.99, 'category': 'Sides'},

      {'name': 'Mango Lassi', 'price': 4.99, 'category': 'Drinks'},
      {'name': 'Masala Chai', 'price': 2.99, 'category': 'Drinks'},
      {'name': 'Cold Coffee', 'price': 3.99, 'category': 'Drinks'},
      {'name': 'Soda', 'price': 1.99, 'category': 'Drinks'},

      {'name': 'Gulab Jamun', 'price': 3.99, 'category': 'Desserts'},
      {'name': 'Brownie', 'price': 3.49, 'category': 'Desserts'},
    ];
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void addItem(String name) {
    setState(() {
      cart[name] = (cart[name] ?? 0) + 1;
    });
  }

  void removeItem(String name) {
    if (!cart.containsKey(name)) return;

    setState(() {
      if (cart[name]! > 1) {
        cart[name] = cart[name]! - 1;
      } else {
        cart.remove(name);
      }
    });
  }

  double get total {
    double sum = 0;
    for (final item in menuItems) {
      final qty = cart[item['name']] ?? 0;
      sum += qty * (item['price'] as double);
    }
    return sum;
  }

  Map<String, List<Map<String, dynamic>>> get groupedMenu {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in menuItems) {
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

  @override
  Widget build(BuildContext context) {
    final grouped = groupedMenu;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.truck['title'] ?? 'Menu'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Choose up to 25 menu items for this business',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 10),
              children: grouped.entries.map((entry) {
                final String category = entry.key;
                final List<Map<String, dynamic>> items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((item) {
                      final String name = item['name'].toString();
                      final double price = item['price'] as double;
                      final int qty = cart[name] ?? 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => removeItem(name),
                                  icon: const Icon(Icons.remove_circle),
                                ),
                                Text(
                                  qty.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => addItem(name),
                                  icon: const Icon(Icons.add_circle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selected Items',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalItemsSelected.toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18),
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