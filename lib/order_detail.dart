import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class OrderDetail extends StatefulWidget {
  final int orderId;

  const OrderDetail({super.key, required this.orderId});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  final supabase = Supabase.instance.client;

  List items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderItems(); // load order items
  }

  Future<void> fetchOrderItems() async {
    try {
      final data = await supabase
          .from('order_item')
          .select('quantity, item:itemid (itemname, itemprice)')
          .eq('orderid', widget.orderId);

      setState(() {
        items = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${widget.orderId}"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text("No items found"))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final orderItem = items[index];
                final item = orderItem['item'];

                return ListTile(
                  title: Text(item['itemname']),
                  subtitle: Text("Qty: ${orderItem['quantity']}"),
                  trailing: Text(
                    "RM ${item['itemprice']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }
}
