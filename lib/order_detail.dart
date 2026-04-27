import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetail extends StatefulWidget {
  final String orderId;

  const OrderDetail({super.key, required this.orderId});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  final supabase = Supabase.instance.client;

  List items = [];
  bool isLoading = true;

  double deliveryFee = 5.0;
  double subtotal = 0;

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
  }

  Future<void> fetchOrderItems() async {
    try {
      final data = await supabase
          .from('order_item')
          .select('quantity, item:itemid (itemname, itemprice)')
          .eq('orderid', widget.orderId);

      double total = 0;

      for (var i in data) {
        final price = (i['item']['itemprice'] ?? 0).toDouble();
        final qty = i['quantity'] ?? 0;
        total += price * qty;
      }

      setState(() {
        items = data;
        subtotal = total;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : items.isEmpty
          ? const Center(child: Text("No items found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Items",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...items.map((i) {
                      final item = i['item'];
                      final price =
                      (item['itemprice'] ?? 0).toDouble();
                      final qty = i['quantity'];

                      return Padding(
                        padding:
                        const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$qty x ${item['itemname']}",
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              "RM ${(price * qty).toStringAsFixed(2)}",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const Divider(height: 24),

                    // SUBTOTAL
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subtotal",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          "RM ${subtotal.toStringAsFixed(2)}",
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // DELIVERY
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Delivery Fee",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          "RM ${deliveryFee.toStringAsFixed(2)}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // TOTAL
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "RM ${(subtotal + deliveryFee).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}