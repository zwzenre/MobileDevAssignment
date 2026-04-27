import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  final double deliveryFee = 5.00;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => _isLoading = false);
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
            .select('*, item(*)')
            .eq('cartid', cartResponse['cartid']);

        setState(() {
          _cartItems = itemsResponse;
        });
      } else {
        setState(() {
          _cartItems = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String cartItemId, int currentQty, int delta) async {
    final newQty = currentQty + delta;
    try {
      if (newQty < 1) {
        await Supabase.instance.client
            .from('cart_item')
            .delete()
            .eq('cartitemid', cartItemId);
      } else {
        await Supabase.instance.client
            .from('cart_item')
            .update({'quantity': newQty})
            .eq('cartitemid', cartItemId);
      }

      await _fetchCartItems();

      if (mounted && _cartItems.isEmpty) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  double get subtotal {
    double total = 0;
    for (var i in _cartItems) {
      final price = num.tryParse((i['item']?['itemprice'] ?? 0).toString())?.toDouble() ?? 0.0;
      final qty = i['quantity'] as int;
      total += (price * qty);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 18)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return _buildCartItemCard(item);
        },
      ),
      bottomNavigationBar: _buildBottomSummary(),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> cartItem) {
    final itemData = cartItem['item'] ?? {};
    final price = num.tryParse((itemData['itemprice'] ?? 0).toString())?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.orange.shade100,
                child: itemData['image_url'] != null && itemData['image_url'].toString().isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: itemData['image_url'],
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: Colors.orange),
                )
                    : const Icon(Icons.fastfood, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemData['itemname'] ?? 'Unknown Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                  onPressed: () => _updateQuantity(cartItem['cartitemid'], cartItem['quantity'], -1),
                ),
                Text('${cartItem['quantity']}', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                  onPressed: () => _updateQuantity(cartItem['cartitemid'], cartItem['quantity'], 1),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    if (_cartItems.isEmpty || _isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                Text('RM ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                Text('RM ${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'RM ${(subtotal + deliveryFee).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Payment())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}