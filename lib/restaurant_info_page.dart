import 'package:flutter/material.dart';

class RestaurantInfoPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantInfoPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Info'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant['description'] != null && restaurant['description'].toString().isNotEmpty) ...[
              const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(restaurant['description'], style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
            ],
            const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
                title: const Text('Delivery Address'),
                subtitle: Text(restaurant['address'] ?? restaurant['resaddress'] ?? '123 Food Street'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Business Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _buildInfoRow('Monday - Friday', '10:00 AM - 10:00 PM'),
                  _buildInfoRow('Saturday', '11:00 AM - 11:00 PM'),
                  _buildInfoRow('Sunday', '11:00 AM - 9:00 PM'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.phone, color: theme.colorScheme.primary),
                    title: const Text('Phone'),
                    subtitle: Text(restaurant['phone'] ?? restaurant['resphone'] ?? '+60 12 345 6789'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email, color: theme.colorScheme.primary),
                    title: const Text('Email'),
                    subtitle: Text(restaurant['email'] ?? 'restaurant@foodapp.com'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}