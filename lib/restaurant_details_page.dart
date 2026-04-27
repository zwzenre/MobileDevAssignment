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
          .where((item) =>
      item['restaurant_id'] == widget.restaurant['id'] ||
          item['resid'] == widget.restaurant['id'])
          .where((item) =>
      item['is_available'] != false &&
          item['availability'] != false)
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
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.restaurant['resname'] ?? 'Restaurant',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                      widget.restaurant['image_url']
                          .toString()
                          .isNotEmpty
                      ? Image.network(
                    widget.restaurant['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.primary,
                      child: Center(
                        child: Icon(Icons.restaurant,
                            size: 80,
                            color:
                            theme.colorScheme.onPrimary),
                      ),
                    ),
                  )
                      : Container(
                    color: theme.colorScheme.primary,
                    child: Center(
                      child: Icon(Icons.restaurant,
                          size: 80,
                          color: theme.colorScheme.onPrimary),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickInfo(Icons.star,
                          widget.restaurant['rating']?.toString() ?? 'New',
                          theme.colorScheme.primary),
                      _buildQuickInfo(
                          Icons.access_time,
                          widget.restaurant['delivery_time'] != null
                              ? '${widget.restaurant['delivery_time']} min'
                              : '30 min',
                          theme.colorScheme.secondary),
                      _buildQuickInfo(
                          Icons.motorcycle,
                          widget.restaurant['delivery_fee'] != null
                              ? 'RM${widget.restaurant['delivery_fee']}'
                              : 'RM0',
                          theme.colorScheme.tertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),

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
                            builder: (context) =>
                                RestaurantInfoPage(
                                    restaurant: widget.restaurant),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Restaurant Info'),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                        side: BorderSide(
                            color:
                            theme.colorScheme.primary),
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
                            builder: (context) =>
                                ReviewsPage(
                                    restaurant: widget.restaurant),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review,
                          size: 18),
                      label: const Text('Reviews'),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                        side: BorderSide(
                            color:
                            theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          _isLoadingMenu
              ? SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(
                    color:
                    theme.colorScheme.primary)),
          )
              : _menuItems.isEmpty
              ? const SliverFillRemaining(
            child: Center(
                child: Text(
                    'No menu items available')),
          )
              : SliverList(
            delegate:
            SliverChildBuilderDelegate(
                  (context, index) =>
                  _buildMenuItemCard(
                      _menuItems[index]),
              childCount: _menuItems.length,
            ),
          ),
        ],
      ),

      bottomNavigationBar: _cartItemCount > 0
          ? Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
              backgroundColor:
              theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                  vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(30),
              ),
            ),
            icon: Icon(Icons.shopping_cart,
                size: 20,
                color:
                theme.colorScheme.onPrimary),
            label: Text(
              'View Cart ($_cartItemCount)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme
                      .colorScheme.onPrimary),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildQuickInfo(
      IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemname'] ??
                        item['name'] ??
                        'Menu Item',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _addToCart(item),
              style: IconButton.styleFrom(
                backgroundColor:
                theme.colorScheme.primary,
                foregroundColor:
                theme.colorScheme.onPrimary,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.add, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.fastfood,
            color:
            theme.colorScheme.onPrimaryContainer),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // check login
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in')),
        );
        return;
      }

      // safe delivery fee
      final deliveryFee = double.tryParse(
        widget.restaurant['delivery_fee']?.toString() ?? '5.0',
      ) ?? 5.0;

      // safe restaurant id
      final restaurantId =
          widget.restaurant['resid'] ?? widget.restaurant['id'];

      // get or create cart
      var cart = await supabase
          .from('cart')
          .select()
          .eq('userid', user.id)
          .eq('status', 'active')
          .maybeSingle();

      String cartId;

      if (cart == null) {
        final newCart = await supabase.from('cart').insert({
          'userid': user.id,
          'status': 'active',
          'subtotal': 0,
          'delivery_fee': deliveryFee,
          'restaurant_id': restaurantId,
        }).select().single();

        cartId = newCart['cartid'];
      } else {
        cartId = cart['cartid'];
      }

      // get item id
      final itemId = item['itemid'] ?? item['id'];

      // check existing item
      var existing = await supabase
          .from('cart_item')
          .select()
          .eq('cartid', cartId)
          .eq('itemid', itemId)
          .maybeSingle();

      if (existing != null) {
        // update qty
        await supabase.from('cart_item').update({
          'quantity': existing['quantity'] + 1,
        }).eq('cartitemid', existing['cartitemid']);
      } else {
        // insert new item
        await supabase.from('cart_item').insert({
          'cartid': cartId,
          'itemid': itemId,
          'quantity': 1,
        });
      }

      // success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['itemname']} added')),
      );

      // refresh cart count
      await _fetchCartItemCount();
    } catch (e) {
      // error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}