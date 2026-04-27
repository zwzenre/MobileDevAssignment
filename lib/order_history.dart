import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_detail.dart';
import 'package:intl/intl.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final supabase = Supabase.instance.client;

  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final data = await supabase
            .from('order')
            .select()
            .eq('userid', user.id)
            .order('orderid', ascending: false); // fixed sorting

        setState(() {
          orders = data;
        });
      } else {
        orders = [];
      }
    } catch (e) {
      print(e);
      orders = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      )
          : orders.isEmpty
          ? const Center(
        child: Text(
          "No orders yet",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            final date = DateTime.parse(order['created_at']);
            final formattedDate = DateFormat('dd MMM yyyy • hh:mm a').format(date);

            final shortId = order['orderid'].toString().substring(0, 6);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetail(orderId: order['orderid']),
                    ),
                  );
                },

                // LEFT SIDE
                title: Text(
                  "Order #$shortId",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(formattedDate, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 6),

                    // status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Completed",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // RIGHT SIDE
                trailing: Text(
                  "RM ${order['totalprice']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            );
          }
      ),
    );
  }
}