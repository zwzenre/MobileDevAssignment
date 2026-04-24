import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: service.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final category = data[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: category['image_url'] != null &&
                          category['image_url'].toString().isNotEmpty
                          ? Image.network(
                        category['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                          : _placeholder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    category['categoryname'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // fallback UI
  Widget _placeholder() {
    return Container(
      color: Colors.orange.shade100,
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.orange, size: 28),
      ),
    );
  }
}