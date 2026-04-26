import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _fetchMenuItems() async {
    try {
      final allItems = await _service.getItems();

      // Filter items for this restaurant
      final restaurantItems = allItems
          .where((item) => item['resid'] == widget.restaurantId || item['restaurant_id'] == widget.restaurantId)
          .where((item) => item['availability'] != false && item['is_available'] != false)
          .toList();

      setState(() {
        _menuItems = restaurantItems;
        _filteredItems = restaurantItems;
        _extractCategories();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load menu: $e');
    }
  }

  void _extractCategories() {
    final categories = _menuItems
        .map((item) => item['categoryname']?.toString() ?? item['category']?.toString() ?? 'General')
        .toSet()
        .toList();
    categories.sort();
    _categories = ['All', ...categories];
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = _menuItems.where((item) {
        final name = (item['itemname'] ?? item['name'] ?? '').toLowerCase();
        final description = (item['itemdesc'] ?? item['description'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredItems = _menuItems;
      } else {
        _filteredItems = _menuItems
            .where((item) => (item['categoryname'] ?? item['category'] ?? 'General') == category)
            .toList();
      }
    });
  }

  // UPDATED: Fully Integrated Supabase Cart Logic
  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showError('Please log in to add items to your cart.');
        return;
      }

      // Show immediate feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adding ${item['itemname'] ?? item['name']} to cart...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // 1. Get or create active cart
      var cartResponse = await supabase
          .from('cart')
          .select()
          .eq('userid', user.id)
          .eq('status', 'active')
          .maybeSingle();

      String cartId;
      if (cartResponse == null) {
        final newCart = await supabase
            .from('cart')
            .insert({'userid': user.id, 'status': 'active', 'subtotal': 0})
            .select()
            .single();
        cartId = newCart['cartid'];
      } else {
        cartId = cartResponse['cartid'];
      }

      // Get appropriate Item ID based on schema
      final itemId = item['itemid'] ?? item['id'];

      // 2. Check if item already exists in cart
      var existingItem = await supabase
          .from('cart_item')
          .select()
          .eq('cartid', cartId)
          .eq('itemid', itemId)
          .maybeSingle();

      if (existingItem != null) {
        // Update existing quantity
        await supabase.from('cart_item').update({
          'quantity': existingItem['quantity'] + 1,
        }).eq('cartitemid', existingItem['cartitemid']);
      } else {
        // Insert new cart item (Removed 'price' to match schema)
        await supabase.from('cart_item').insert({
          'cartid': cartId,
          'itemid': itemId,
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['itemname'] ?? item['name']} added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to add to cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _filterItems(''),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterItems,
                ),
              ),
              // Category Chips
              if (_categories.isNotEmpty)
                Container(
                  height: 45,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            _filterByCategory(category);
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : Colors.black87,
                          ),
                          backgroundColor: Colors.grey[200],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Loading menu...'),
          ],
        ),
      )
          : _filteredItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No items match "$_searchQuery"'
                  : 'No menu items available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _filterItems(''),
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildMenuItemCard(item);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                  ? Image.network(
                item['image_url'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.orange[100],
                  child: const Icon(Icons.fastfood, size: 40, color: Colors.orange),
                ),
              )
                  : Container(
                width: 100,
                height: 100,
                color: Colors.orange[100],
                child: const Icon(Icons.fastfood, size: 40, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Category Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['itemname'] ?? item['name'] ?? 'Menu Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item['categoryname'] != null || item['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['categoryname'] ?? item['category'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if ((item['itemdesc'] ?? item['description']) != null && (item['itemdesc'] ?? item['description']).toString().isNotEmpty)
                    Text(
                      item['itemdesc'] ?? item['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₱${(item['itemprice'] ?? item['price'])?.toString() ?? '0'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          if (item['availability'] == false || item['is_available'] == false)
                            Text(
                              'Currently unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red[400],
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: (item['availability'] != false && item['is_available'] != false)
                            ? () => _addToCart(item)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Add'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}