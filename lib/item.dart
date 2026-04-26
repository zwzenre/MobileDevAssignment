import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Item extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  const Item({super.key, this.itemData});

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  late final Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = widget.itemData ??
        {
          'itemid': '00000000-0000-0000-0000-000000000000',
          'itemname': 'Sample Delicious Meal',
          'itemprice': 15.50,
          'itemdesc': 'A wonderful, mouth-watering dish cooked to perfection with our secret recipe of herbs and spices.',
          'image_url': '',
        };
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please log in to add items to your cart.');
      }

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

      // 2. Check if item already exists in cart
      var existingItem = await supabase
          .from('cart_item')
          .select()
          .eq('cartid', cartId)
          .eq('itemid', _item['itemid'])
          .maybeSingle();

      if (existingItem != null) {
        // Update existing quantity
        await supabase.from('cart_item').update({
          'quantity': existingItem['quantity'] + _quantity,
        }).eq('cartitemid', existingItem['cartitemid']);
      } else {
        // Insert new cart item
        await supabase.from('cart_item').insert({
          'cartid': cartId,
          'itemid': _item['itemid'],
          'quantity': _quantity,
          'price': _item['itemprice'] ?? _item['price'] ?? 0,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Cart!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double price = num.tryParse((_item['itemprice'] ?? _item['price'] ?? 0).toString())?.toDouble() ?? 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _item['image_url'] != null && _item['image_url'].toString().isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: _item['image_url'],
                fit: BoxFit.cover,
                placeholder: (context, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),
          ),

          // Item Details Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _item['itemname'] ?? _item['name'] ?? 'Item Details',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'RM ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _item['itemdesc'] ?? _item['description'] ?? 'No description available for this item.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Special Instructions Text Area
                    const Text(
                      'Special Instructions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. No onions, extra spicy...',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.orange),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.orange),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isAddingToCart
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    'Add RM ${(price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.orange.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.fastfood, size: 80, color: Colors.orange),
      ),
    );
  }
}