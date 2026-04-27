import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final SupabaseService _service = SupabaseService();

  List<dynamic> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final allItems = await _service.getItems();

      List filtered = allItems;

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
      print("Error: $e");
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

          return Card(
            color: theme.colorScheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
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

              subtitle: Text(
                i['itemdesc'] ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
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