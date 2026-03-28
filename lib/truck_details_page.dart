import 'package:flutter/material.dart';

class TruckDetailsPage extends StatelessWidget {
  final String name;
  final String type;

  const TruckDetailsPage({
    super.key,
    required this.name,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHomeKitchen = type == 'home';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isHomeKitchen ? 'Home Kitchen' : 'Food Truck',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sample menu:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isHomeKitchen
                  ? '• Homemade Curry\n• Fresh Roti\n• Rice Bowl\n• Dessert'
                  : '• Tacos\n• Burger\n• Fries\n• Cold Drinks',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is a sample details page. Later we will connect real truck and home kitchen data from the portal.',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}