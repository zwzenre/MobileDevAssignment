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

  double deliveryFee = 0;
  double subtotal = 0;
  double total = 0;
  double discount = 0;

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
  }

  Future<void> fetchOrderItems() async {
    try {
      // get order data
      final orderData = await supabase
          .from('order')
          .select('totalprice, delivery_fee, discount')
          .eq('orderid', widget.orderId)
          .single();

      total = double.tryParse(orderData['totalprice'].toString()) ?? 0.0;
      deliveryFee =
          double.tryParse(orderData['delivery_fee'].toString()) ?? 0.0;
      discount =
          double.tryParse(orderData['discount'].toString()) ?? 0.0;

      // get items
      final data = await supabase
          .from('order_item')
          .select('quantity, price, item:itemid (itemname)')
          .eq('orderid', widget.orderId);

      double tempSubtotal = 0;

      for (var i in data) {
        final price =
            double.tryParse(i['price'].toString()) ?? 0.0;
        final qty = i['quantity'] ?? 0;

        tempSubtotal += price * qty;
      }

      setState(() {
        items = data;
        subtotal = tempSubtotal;
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
          ? const Center(
        child: Text("No items found"),
      )
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // items
                    ...items.map((i) {
                      final item = i['item'];
                      if (item == null) return const SizedBox();

                      final price = double.tryParse(
                        i['price'].toString(),
                      ) ??
                          0.0;

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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              "RM ${(price * qty).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const Divider(height: 24),

                    // subtotal
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text(
                          "RM ${subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // delivery
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery Fee"),
                        Text(
                          "RM ${deliveryFee.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    // discount
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Discount",
                            style:
                            TextStyle(color: Colors.green),
                          ),
                          Text(
                            "- RM ${discount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // total
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "RM ${total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                            theme.colorScheme.primary,
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