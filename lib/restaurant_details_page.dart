import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'cart.dart';
import 'restaurant_info_page.dart';
import 'reviews_page.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final SupabaseService _service = SupabaseService();
  List<dynamic> _menuItems = [];
  bool _isLoadingMenu = true;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
    _fetchCartItemCount();
  }

  Future<void> _fetchCartItemCount() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => _cartItemCount = 0);
        return;
      }

      final cartResponse = await supabase
          .from('cart')
          .select()
          .eq('userid', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (cartResponse != null) {
        final itemsResponse = await supabase
            .from('cart_item')
            .select()
            .eq('cartid', cartResponse['cartid']);

        setState(() {
          _cartItemCount = itemsResponse.length;
        });
      } else {
        setState(() {
          _cartItemCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
      setState(() => _cartItemCount = 0);
    }
  }

  Future<void> _fetchMenuItems() async {
    try {
      final allItems = await _service.getItems();
      final restaurantItems = allItems
          .where((item) => item['restaurant_id'] == widget.restaurant['id'] || item['resid'] == widget.restaurant['id'])
          .where((item) => item['is_available'] != false && item['availability'] != false)
          .toList();

      setState(() {
        _menuItems = restaurantItems;
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
      debugPrint('Error fetching menu items: $e');
    }
  }


  Future<void> _navigateToCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Cart()),
    );

    await _fetchCartItemCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.restaurant['resname'] ?? 'Restaurant',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.restaurant['image_url'] != null &&
                      widget.restaurant['image_url'].toString().isNotEmpty
                      ? Image.network(
                    widget.restaurant['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.orange,
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 80, color: Colors.white),
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.orange,
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 80, color: Colors.white),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16), // Increased padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickInfo(Icons.star, widget.restaurant['rating']?.toString() ?? 'New', Colors.orange),
                        _buildQuickInfo(Icons.access_time, widget.restaurant['delivery_time'] != null ? '${widget.restaurant['delivery_time']} min' : '30 min', Colors.blue),
                        _buildQuickInfo(Icons.motorcycle, widget.restaurant['delivery_fee'] != null ? 'RM${widget.restaurant['delivery_fee']}' : 'RM0', Colors.green),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Navigation Buttons (Info & Reviews)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantInfoPage(restaurant: widget.restaurant),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Restaurant Info'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewsPage(restaurant: widget.restaurant),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Reviews'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Menu Items List
          _isLoadingMenu
              ? const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Colors.orange)),
          )
              : _menuItems.isEmpty
              ? const SliverFillRemaining(
            child: Center(child: Text('No menu items available')),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMenuItemCard(_menuItems[index]),
              childCount: _menuItems.length,
            ),
          ),
        ],
      ),

      // View Cart Button - Only shows when cart has items
      bottomNavigationBar: _cartItemCount > 0
          ? Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _navigateToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.shopping_cart, size: 20),
            label: Text(
              'View Cart ($_cartItemCount)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildQuickInfo(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10), // Increased padding
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28), // Increased icon size from 20 to 28
        ),
        const SizedBox(height: 8), // Increased spacing
        Text(
          label,
          style: TextStyle(
            fontSize: 14, // Increased font size from 11 to 14
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                    ? Image.network(
                  item['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemname'] ?? item['name'] ?? 'Menu Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if ((item['itemdesc'] ?? item['description'] ?? '').toString().isNotEmpty)
                    Text(
                      item['itemdesc'] ?? item['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM${(item['itemprice'] ?? item['price'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: (item['availability'] != false && item['is_available'] != false)
                      ? () => _addToCart(item)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(6),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.orange.shade100,
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.orange, size: 30),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final deliveryFee = (widget.restaurant['delivery_fee'] ?? 5.0).toDouble();
      final restaurantId = widget.restaurant['id'] ?? widget.restaurant['resid'];

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
            .insert({
          'userid': user.id,
          'status': 'active',
          'subtotal': 0,
          'delivery_fee': deliveryFee,
          'restaurant_id': restaurantId,
        })
            .select()
            .single();
        cartId = newCart['cartid'];
      } else {
        cartId = cartResponse['cartid'];

        if ((cartResponse['delivery_fee'] ?? 5.0) != deliveryFee) {
          await supabase
              .from('cart')
              .update({
            'delivery_fee': deliveryFee,
            'restaurant_id': restaurantId
          })
              .eq('cartid', cartId);
        }
      }

      final itemId = item['itemid'] ?? item['id'];

      var existingItem = await supabase
          .from('cart_item')
          .select()
          .eq('cartid', cartId)
          .eq('itemid', itemId)
          .maybeSingle();

      if (existingItem != null) {
        await supabase.from('cart_item').update({
          'quantity': existingItem['quantity'] + 1,
        }).eq('cartitemid', existingItem['cartitemid']);
      } else {
        await supabase.from('cart_item').insert({
          'cartid': cartId,
          'itemid': itemId,
          'quantity': 1,
        });
      }

      final cartItems = await supabase
          .from('cart_item')
          .select('*, item(*)')
          .eq('cartid', cartId);

      double newSubtotal = 0;
      for (var cartItem in cartItems) {
        final price = (cartItem['item']['itemprice'] ?? 0).toDouble();
        final qty = (cartItem['quantity'] ?? 1).toDouble();
        newSubtotal += price * qty;
      }

      await supabase
          .from('cart')
          .update({'subtotal': newSubtotal})
          .eq('cartid', cartId);

      await _fetchCartItemCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['itemname'] ?? item['name']} added!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}