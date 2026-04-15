import 'package:flutter/material.dart';
import 'role_selection_page.dart';


void main() {
  runApp(const MapMyBiteApp());
}

class MapMyBiteApp extends StatelessWidget {
  const MapMyBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionPage(),
    );
  }
}