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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredItems.isEmpty
          ? const Center(
        child: Text(
          "No items in this category",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final i = _filteredItems[index];
          return Card(
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
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),

                errorWidget: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
              title: Text(i['itemname'] ?? ''),
              subtitle: Text(i['itemdesc'] ?? ''),
              trailing: Text(
                'RM ${(i['itemprice'] ?? 0).toDouble().toStringAsFixed(2)}',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 70,
    height: 70,
    color: Colors.orange.shade100,
    child: const Icon(Icons.fastfood, color: Colors.orange),
  );
}