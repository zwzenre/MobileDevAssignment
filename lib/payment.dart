import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_address.dart';
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

  // apply promo
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

      final order = await supabase.from('order').insert({
        'userid': user.id,
        'totalprice': _subtotal + _deliveryFee - _discount,
        'status': 'pending',
      }).select().single();

      for (var item in _cartItems) {
        await supabase.from('order_item').insert({
          'orderid': order['orderid'],
          'itemid': item['itemid'],
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
        Navigator.popUntil(context, (route) => route.isFirst);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // address
            const Text(
              'Delivery Address',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on,
                      color: theme.colorScheme.primary),
                ),
                title: const Text(
                  'Home',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                const Text('123 Jalan Ampang, Kuala Lumpur'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditAddressPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Change',
                    style:
                    TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // summary
            const Text(
              'Order Summary',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ..._cartItems.map((cartItem) {
                      final itemData = cartItem['item'] ?? {};
                      final price = num.tryParse(
                          (itemData['itemprice'] ?? 0)
                              .toString())
                          ?.toDouble() ??
                          0.0;

                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  '${cartItem['quantity']}x ${itemData['itemname'] ?? 'Item'}'),
                            ),
                            Text(
                                'RM ${(price * cartItem['quantity']).toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                            'RM ${_subtotal.toStringAsFixed(2)}'),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                            'RM ${_deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),

                    // discount
                    if (_discount > 0)
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount',
                              style:
                              TextStyle(color: Colors.green)),
                          Text(
                            '- RM ${_discount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // promo
            const Text(
              'Promotion',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer,
                      color: theme.colorScheme.primary),
                ),

                // show promo
                title: Text(
                  _selectedPromo == null
                      ? 'Apply Promo'
                      : _selectedPromo!['code'],
                  style:
                  const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: _selectedPromo != null
                    ? Text(_selectedPromo!['description'] ?? '')
                    : null,

                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.primary),

                onTap: () async {
                  final promo = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PromoPage()),
                  );

                  if (promo != null) {
                    _applyPromo(promo);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // payment
            const Text(
              'Payment Method',
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildPaymentOption(
                0, Icons.money, 'Cash on Delivery'),
            _buildPaymentOption(1,
                Icons.account_balance_wallet, 'E-Wallet / TNG'),
            _buildPaymentOption(
                2, Icons.credit_card, 'Credit / Debit Card'),

            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed:
            (_cartItems.isEmpty || _isLoading) ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Place Order - RM ${(_subtotal + _deliveryFee - _discount).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      int index, IconData icon, String title) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () =>
          setState(() => _selectedPaymentMethod = index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle,
                color: theme.colorScheme.primary)
                : const Icon(Icons.circle_outlined,
                color: Colors.grey),
          ),
        ),
      ),
    );
  }
}