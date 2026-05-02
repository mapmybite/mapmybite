import 'package:flutter/foundation.dart';

class FavoriteData {
  static void removeFavorite(Map<String, dynamic> business) {
    final String id = (business['id'] ?? business['title'] ?? '').toString();

    final List<Map<String, dynamic>> updated =
    List<Map<String, dynamic>>.from(favorites.value);

    updated.removeWhere(
          (item) => (item['id'] ?? item['title'] ?? '').toString() == id,
    );

    favorites.value = updated;
  }
  static final ValueNotifier<List<Map<String, dynamic>>> favorites =
  ValueNotifier<List<Map<String, dynamic>>>([]);

  static bool isFavorite(Map<String, dynamic> business) {
    final String id = (business['id'] ?? business['title'] ?? '').toString();

    return favorites.value.any(
          (item) => (item['id'] ?? item['title'] ?? '').toString() == id,
    );
  }

  static void toggleFavorite(Map<String, dynamic> business) {
    final String id = (business['id'] ?? business['title'] ?? '').toString();

    final List<Map<String, dynamic>> updated =
    List<Map<String, dynamic>>.from(favorites.value);

    final int index = updated.indexWhere(
          (item) => (item['id'] ?? item['title'] ?? '').toString() == id,
    );

    if (index == -1) {
      updated.add(business);
    } else {
      updated.removeAt(index);
    }

    favorites.value = updated;
  }
}