import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class AllItemsPage extends StatelessWidget {
  const AllItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Items"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: item['image_url'] != null &&
                              item['image_url']
                                  .toString()
                                  .isNotEmpty
                              ? Image.network(
                            item['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(),
                          )
                              : _placeholder(),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // text
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['itemname'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            if ((item['itemdesc'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Text(
                                item['itemdesc'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                const TextStyle(fontSize: 13),
                              ),

                            const SizedBox(height: 6),

                            Text(
                              item['ishalal'] == true
                                  ? 'Halal'
                                  : 'Non-Halal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item['ishalal'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // price
                      Text(
                        'RM ${(item['itemprice'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // placeholder
  Widget _placeholder() {
    return Container(
      color: Colors.orange.shade100,
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.orange),
      ),
    );
  }
}