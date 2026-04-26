import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class MenuPage extends StatefulWidget {
  final dynamic restaurantId;
  final String restaurantName;

  const MenuPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final SupabaseService _service = SupabaseService();

  List<dynamic> _menuItems = [];
  List<dynamic> _filteredItems = [];
  List<String> _categories = [];

  String _selectedCategory = 'All';
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  // load menu
  Future<void> _fetchMenuItems() async {
    try {
      final allItems = await _service.getItems();

      final restaurantItems = allItems
          .where((item) => item['restaurant_id'] == widget.restaurantId)
          .where((item) => item['is_available'] != false)
          .toList();

      setState(() {
        _menuItems = restaurantItems;
        _filteredItems = restaurantItems;
        _extractCategories();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('failed to load menu');
    }
  }

  // extract category
  void _extractCategories() {
    final cats = _menuItems
        .map((item) => item['category']?.toString() ?? 'General')
        .toSet()
        .toList();

    cats.sort();
    _categories = ['All', ...cats];
  }

  // search filter
  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = _menuItems.where((item) {
        final name = item['name']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  // category filter
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;

      if (category == 'All') {
        _filteredItems = _menuItems;
      } else {
        _filteredItems = _menuItems
            .where((item) => (item['category'] ?? 'General') == category)
            .toList();
      }
    });
  }

  // add to cart
  void _addToCart(Map item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('added ${item['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),

        // use theme color
        backgroundColor: primary,
        foregroundColor: Colors.white,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // search
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'search menu',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // categories
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selected,

                        // use theme color
                        selectedColor: primary,
                        checkmarkColor: Colors.white,

                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                        ),

                        backgroundColor: Theme.of(context).cardColor,

                        onSelected: (_) => _filterByCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildItem(item);
        },
      ),
    );
  }

  Widget _buildItem(Map item) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // image
            Container(
              width: 90,
              height: 90,
              color: Theme.of(context).cardColor,
              child: const Icon(Icons.fastfood),
            ),

            const SizedBox(width: 12),

            // details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${item['price']}',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () => _addToCart(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),
                        child: const Text('add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}