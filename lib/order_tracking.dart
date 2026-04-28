import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_navigation.dart';
import 'order_history.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? orderId;

  const OrderTrackingPage({super.key, this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  int _currentStep = 0;
  Timer? _timer;

  final LatLng _restaurantLocation = const LatLng(3.215597, 101.728109);
  final LatLng _userLocation = const LatLng(3.210000, 101.720000);

  @override
  void initState() {
    super.initState();
    _startTrackingSimulation();
  }

  void _startTrackingSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_currentStep < 3) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
        }

        // ✅ When delivered → update DB
        if (_currentStep == 3 && widget.orderId != null) {
          final supabase = Supabase.instance.client;

          await supabase
              .from('order')
              .update({'status': 'completed'})
              .eq('orderid', widget.orderId!);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // navigation
  void _goToOrders() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: 3), // Account tab
      ),
          (route) => false,
    ).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderHistory(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = _currentStep == 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,

        // close button
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _goToOrders,
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // map
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(3.2128, 101.7240),
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.student.fooddeliveryapp',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_restaurantLocation, _userLocation],
                        strokeWidth: 4,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _restaurantLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.storefront,
                            color: Colors.blue, size: 36),
                      ),
                      Marker(
                        point: _userLocation,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // details
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Order #${widget.orderId?.substring(0, 8) ?? ""}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isDelivered ? 'Order Received!' : 'Arriving soon',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 30),

                  _buildStep(0, 'Order Placed',
                      'We have received your order.', Icons.receipt_long),
                  _buildStep(1, 'Preparing Food',
                      'Restaurant is preparing.', Icons.restaurant),
                  _buildStep(2, 'Out for Delivery',
                      'Rider is on the way.', Icons.motorcycle),
                  _buildStep(3, 'Delivered',
                      'Enjoy your meal!', Icons.home, isLast: true),

                  const SizedBox(height: 30),

                  // button
                  if (isDelivered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Back to Main Menu',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepIndex, String title, String subtitle,
      IconData icon,
      {bool isLast = false}) {
    final theme = Theme.of(context);

    bool isCompleted = _currentStep >= stepIndex;
    bool isActive = _currentStep == stepIndex;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isLast && isActive
                    ? Colors.green
                    : theme.colorScheme.primary)
                    : theme.dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isCompleted ? Colors.white : Colors.grey),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: _currentStep > stepIndex
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight:
                        isActive || isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: isActive || isCompleted
                            ? Colors.grey[600]
                            : Colors.grey[400])),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}