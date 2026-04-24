import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class AllRestaurantsPage extends StatelessWidget {
  const AllRestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text("All Restaurants")),
      body: FutureBuilder(
        future: service.getRestaurants(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final r = data[i];
              return ListTile(
                leading: Image.network(r['image_url'] ?? '',
                    width: 60, errorBuilder: (_, __, ___) => const Icon(Icons.restaurant)),
                title: Text(r['resname'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}