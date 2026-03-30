import 'package:flutter/material.dart';

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

  final List<String> categories = const [
    'Main Items',
    'Drinks',
    'Sides',
    'Desserts',
  ];

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMenuItems;
    if (initial != null && initial.isNotEmpty) {
      menuItems = initial.map<Map<String, dynamic>>((item) {
        if (item is Map) {
          return {
            'name': (item['name'] ?? '').toString(),
            'price': (item['price'] ?? '').toString(),
            'category': (item['category'] ?? 'Main Items').toString(),
          };
        }
        return {
          'name': '',
          'price': '',
          'category': 'Main Items',
        };
      }).toList();
    } else {
      menuItems = [
        {
          'name': '',
          'price': '',
          'category': 'Main Items',
        }
      ];
    }
  }

  void _addItem() {
    if (menuItems.length >= 25) return;

    setState(() {
      menuItems.add({
        'name': '',
        'price': '',
        'category': 'Main Items',
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      menuItems.removeAt(index);
      if (menuItems.isEmpty) {
        menuItems.add({
          'name': '',
          'price': '',
          'category': 'Main Items',
        });
      }
    });
  }

  void _saveMenu() {
    final cleaned = menuItems.where((item) {
      final name = item['name'].toString().trim();
      final price = item['price'].toString().trim();
      return name.isNotEmpty && price.isNotEmpty;
    }).map<Map<String, dynamic>>((item) {
      return {
        'name': item['name'].toString().trim(),
        'price': double.tryParse(item['price'].toString().trim()) ?? 0.0,
        'category': item['category'].toString().trim().isEmpty
            ? 'Main Items'
            : item['category'].toString().trim(),
      };
    }).toList();

    Navigator.pop(context, cleaned);
  }

  Widget _buildMenuCard(int index) {
    final item = menuItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
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
          TextFormField(
            initialValue: item['price'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: categories.contains(item['category'])
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
            child: Text(
              'Owner can add up to 25 items. Remaining: $remaining',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
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