import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? orderId;

  const OrderTrackingPage({super.key, this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  int _currentStep = 0;
  Timer? _timer;

  // Mock locations for tracking map
  final LatLng _restaurantLocation = const LatLng(3.215597, 101.728109);
  final LatLng _userLocation = const LatLng(3.210000, 101.720000);

  @override
  void initState() {
    super.initState();
    _startTrackingSimulation();
  }

  void _startTrackingSimulation() {
    // Simulates the order progressing every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentStep < 3) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = _currentStep == 3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map View using OpenStreetMap
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(3.2128, 101.7240), // Center point between both markers
                      initialZoom: 14.5,
                    ),
                    children: [
                      TileLayer(
                        maxZoom: 20,
                        urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.student.fooddeliveryapp',
                      ),
                      // Draws a route line between the restaurant and the user
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_restaurantLocation, _userLocation],
                            strokeWidth: 4.0,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Restaurant Marker
                          Marker(
                            point: _restaurantLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.storefront, color: Colors.blue, size: 36),
                          ),
                          // User/Delivery Marker
                          Marker(
                            point: _userLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isDelivered)
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_bike, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Estimated arrival: 15-20 min',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tracking Details
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${widget.orderId != null ? "#${widget.orderId!.substring(0, 8)}" : "Details"}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDelivered ? 'Order Received!' : 'Arriving soon',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (isDelivered)
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Tracking Timeline
                    _buildStep(
                      stepIndex: 0,
                      title: 'Order Placed',
                      subtitle: 'We have received your order.',
                      icon: Icons.receipt_long,
                      theme: theme,
                    ),
                    _buildStep(
                      stepIndex: 1,
                      title: 'Preparing Food',
                      subtitle: 'The restaurant is preparing your meal.',
                      icon: Icons.restaurant,
                      theme: theme,
                    ),
                    _buildStep(
                      stepIndex: 2,
                      title: 'Out for Delivery',
                      subtitle: 'Your rider is on the way.',
                      icon: Icons.motorcycle,
                      theme: theme,
                    ),
                    _buildStep(
                      stepIndex: 3,
                      title: 'Delivered',
                      subtitle: 'Enjoy your meal!',
                      icon: Icons.home,
                      theme: theme,
                      isLast: true,
                    ),

                    const SizedBox(height: 32),

                    if (isDelivered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildStep({
    required int stepIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    bool isLast = false,
  }) {
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
                color: isCompleted ? (isLast && isActive ? Colors.green : theme.colorScheme.primary) : theme.dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 24
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: _currentStep > stepIndex ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10), // Alignment tweak
              Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive || isCompleted ? theme.textTheme.bodyLarge?.color : Colors.grey.shade600,
                  )
              ),
              const SizedBox(height: 4),
              Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive || isCompleted ? Colors.grey.shade600 : Colors.grey.shade400,
                  )
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}