import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'restaurant_details_page.dart';

class AllItemsPage extends StatefulWidget {
  final dynamic categoryId;
  final String categoryName;

  const AllItemsPage({
    super.key,
    this.categoryId,
    this.categoryName = 'All Items',
  });

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  final supabase = Supabase.instance.client;

  List<dynamic> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      // fetch items with restaurant join
      final allItems = await supabase
          .from('item')
          .select('*, restaurant(*)');

      List filtered = allItems;

      // filter by category if provided
      if (widget.categoryId != null) {
        filtered = allItems.where((i) {
          return i['categoryid']?.toString() ==
              widget.categoryId?.toString();
        }).toList();
      }

      setState(() {
        _filteredItems = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredItems.isEmpty
          ? Center(
        child: Text(
          "No items in this category",
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final i = _filteredItems[index];
          final restaurant = i['restaurant'];

          return Card(
            color: theme.colorScheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () {
                // prevent broken navigation
                if (restaurant == null) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailsPage(
                      restaurant: {
                        'id': restaurant['resid'],
                        'resid': restaurant['resid'],
                        'resname': restaurant['resname'],
                        'image_url': restaurant['image_url'],
                      },
                    ),
                  ),
                );
              },

              // item image
              leading: i['image_url'] != null &&
                  i['image_url'].toString().isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: i['image_url'],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (context, _) => const SizedBox(
                  width: 70,
                  height: 70,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),

              title: Text(
                i['itemname'] ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i['itemdesc'] ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant?['resname'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),

              trailing: Text(
                'RM ${(i['itemprice'] ?? 0).toDouble().toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    final theme = Theme.of(context);

    return Container(
      width: 70,
      height: 70,
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.fastfood,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}