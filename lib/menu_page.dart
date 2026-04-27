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

  // load menu
  Future<void> _fetchMenuItems() async {
    try {
      final allItems = await _service.getItems();

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
        final name = (item['itemname'] ?? item['name'] ?? '').toLowerCase();
        final description = (item['itemdesc'] ?? item['description'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase());
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
            .where((item) => (item['categoryname'] ?? item['category'] ?? 'General') == category)
            .toList();
      }
    });
  }

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

  Widget _buildItem(Map<String, dynamic> item) {
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
                          backgroundColor: primary,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('add'),
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