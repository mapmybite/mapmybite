import 'package:flutter/material.dart';
import 'favorite_data.dart';
import 'truck_profile_page.dart';

class CustomerFavoritesPage extends StatelessWidget {
  const CustomerFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: FavoriteData.favorites,
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorites yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];

              return Card(
                color: const Color(0xFF1F1F1F),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TruckProfilePage(
                          truck: item,
                          isOwner: false,
                          initialIsFavorite: true,
                        ),
                      ),
                    );
                  },
                  leading: const Icon(Icons.store, color: Colors.orange),
                  title: Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    item['cuisine'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      FavoriteData.removeFavorite(item);
                    },
                  ),
                )
              );
            },
          );
        },
      ),
    );
  }
}