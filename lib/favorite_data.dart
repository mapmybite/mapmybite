import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteData {
  static final ValueNotifier<List<Map<String, dynamic>>> favorites =
  ValueNotifier<List<Map<String, dynamic>>>([]);

  static const String _storageKey = 'mapmybite_favorites';

  static Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_storageKey);

    if (savedData == null || savedData.isEmpty) {
      favorites.value = [];
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(savedData);

      favorites.value = decoded
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
        ),
      )
          .toList();
    } catch (_) {
      favorites.value = [];
    }
  }

  static Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(favorites.value);
    await prefs.setString(_storageKey, encoded);
  }

  static String _favoriteId(Map<String, dynamic> business) {
    return (business['id'] ?? business['title'] ?? '').toString();
  }

  static bool isFavorite(Map<String, dynamic> business) {
    final String id = _favoriteId(business);

    return favorites.value.any(
          (item) => _favoriteId(item) == id,
    );
  }

  static Future<void> toggleFavorite(Map<String, dynamic> business) async {
    final String id = _favoriteId(business);

    final List<Map<String, dynamic>> updated =
    List<Map<String, dynamic>>.from(favorites.value);

    final int index = updated.indexWhere(
          (item) => _favoriteId(item) == id,
    );

    if (index == -1) {
      updated.add(Map<String, dynamic>.from(business));
    } else {
      updated.removeAt(index);
    }

    favorites.value = updated;
    await _saveFavorites();
  }

  static Future<void> removeFavorite(Map<String, dynamic> business) async {
    final String id = _favoriteId(business);

    final List<Map<String, dynamic>> updated =
    List<Map<String, dynamic>>.from(favorites.value);

    updated.removeWhere(
          (item) => _favoriteId(item) == id,
    );

    favorites.value = updated;
    await _saveFavorites();
  }
}