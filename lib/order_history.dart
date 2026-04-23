import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_detail.dart';

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
    fetchOrders(); // load orders
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final data = await supabase
            .from('order')
            .select()
            .eq('userid', user.id)
            .order('orderdate', ascending: false);

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
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetail(
                      orderId: order['orderid'],
                    ),
                  ),
                );
              },
              title: Text("Order #${order['orderid']}"),
              subtitle: Text("Date: ${order['orderdate']}"),
              trailing: Text(
                "RM ${order['totalamount']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}