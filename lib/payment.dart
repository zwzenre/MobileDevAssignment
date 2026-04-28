import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_address.dart';
import 'order_tracking.dart';
import 'promo_page.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  int _selectedPaymentMethod = 0;
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  String? _cartId;

  double _deliveryFee = 0.0;

  // promo
  Map? _selectedPromo;
  double _discount = 0;

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

      if (user != null) {
        final cartResponse = await supabase
            .from('cart')
            .select()
            .eq('userid', user.id)
            .eq('status', 'active')
            .maybeSingle();

        if (cartResponse != null) {
          _cartId = cartResponse['cartid'];

          final restaurantId = cartResponse['resid'];

          if (restaurantId != null) {
            final restaurant = await supabase
                .from('restaurant')
                .select('delivery_fee')
                .eq('resid', restaurantId)
                .single();

            _deliveryFee =
                (restaurant['delivery_fee'] as num?)?.toDouble() ?? 0.0;
          }

          final itemsResponse = await supabase
              .from('cart_item')
              .select('*, item(*)')
              .eq('cartid', _cartId as Object);

          setState(() {
            _cartItems = itemsResponse;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _subtotal {
    double total = 0;
    for (var i in _cartItems) {
      final price = num.tryParse(
          (i['item']?['itemprice'] ?? 0).toString())
          ?.toDouble() ??
          0.0;

      final qty = i['quantity'] as int;
      total += (price * qty);
    }
    return total;
  }

  // promo logic
  void _applyPromo(Map promo) {
    double discount = 0;

    if (promo['discount_type'] == 'percentage') {
      discount = _subtotal * (promo['discount_value'] / 100);
    } else {
      discount = promo['discount_value'].toDouble();
    }

    setState(() {
      _selectedPromo = promo;
      _discount = discount;
    });
  }

  Future<void> _placeOrder() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null || _cartId == null) return;

      final total = _subtotal + _deliveryFee - _discount;

      final order = await supabase.from('order').insert({
        'userid': user.id,
        'totalprice': total,
        'status': 'pending',
      }).select().single();

      for (var item in _cartItems) {
        await supabase.from('order_item').insert({
          'orderid': order['orderid'],
          'itemid': item['itemid'] ?? item['item']?['itemid'],
          'quantity': item['quantity'],
          'price': item['price'] ?? item['item']?['itemprice'],
        });
      }

      await supabase
          .from('cart')
          .update({'status': 'completed'})
          .eq('cartid', _cartId as Object);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order Placed Successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OrderTrackingPage(orderId: order['orderid']),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = _subtotal + _deliveryFee - _discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              color: theme.colorScheme.primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // address
                  const Text('Delivery Address',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                    child: ListTile(
                      title: const Text('Home'),
                      subtitle:
                      const Text('123 Jalan Ampang'),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const EditAddressPage()),
                          );
                        },
                        child: const Text('Change'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // summary
                  const Text('Order Summary',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [

                          ..._cartItems.map((cartItem) {
                            final itemData =
                                cartItem['item'] ?? {};

                            final price = num.tryParse(
                                (itemData['itemprice'] ?? 0)
                                    .toString())
                                ?.toDouble() ??
                                0.0;

                            return Padding(
                              padding:
                              const EdgeInsets.only(
                                  bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                      '${cartItem['quantity']}x ${itemData['itemname']}'),
                                  Text(
                                    'RM ${(price * cartItem['quantity']).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const Divider(),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text(
                                'RM ${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              const Text('Delivery Fee'),
                              Text(
                                'RM ${_deliveryFee.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          if (_discount > 0)
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                const Text('Discount',
                                    style: TextStyle(
                                        color:
                                        Colors.green)),
                                Text(
                                  '- RM ${_discount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // promo
                  const Text('Promotion',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),

                  ListTile(
                    title: Text(
                      _selectedPromo == null
                          ? 'Apply Promo'
                          : _selectedPromo!['code'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    trailing:
                    const Icon(Icons.chevron_right),
                    onTap: () async {
                      final promo = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const PromoPage()),
                      );

                      if (promo != null)
                        _applyPromo(promo);
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(
                      'RM ${(_subtotal + _deliveryFee - _discount).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                        theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_cartItems.isEmpty ||
                        _isLoading)
                        ? null
                        : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      theme.colorScheme.primary,
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 14),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            30),
                      ),
                    ),
                    child: Text(
                      'Place Order - RM ${(_subtotal + _deliveryFee - _discount).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme
                              .colorScheme.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // bottom buttons
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // cart tab active
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            // navigate to search
          } else if (index == 2) {
            Navigator.pop(context);
          } else if (index == 3) {
            // navigate to account
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}