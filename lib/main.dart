import 'package:flutter/material.dart';
import 'truck_page.dart';

void main() {
  runApp(const MapMyBiteApp());
}

class MapMyBiteApp extends StatelessWidget {
  const MapMyBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TruckPage(),
    );
  }
}