import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'menu_page.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final SupabaseService _service = SupabaseService();
  List<dynamic> _menuItems = [];
  bool _isLoadingMenu = true;
  int _selectedTab = 0; // 0: Menu, 1: Info, 2: Reviews

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      final allItems = await _service.getItems();
      final restaurantItems = allItems
          .where((item) => item['restaurant_id'] == widget.restaurant['id'])
          .where((item) => item['is_available'] != false)
          .take(5)
          .toList();

      setState(() {
        _menuItems = restaurantItems;
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() => _isLoadingMenu = false);
      debugPrint('Error fetching menu items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image with App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.restaurant['resname'] ?? 'Restaurant',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Restaurant Image
                  widget.restaurant['image_url'] != null &&
                      widget.restaurant['image_url'].toString().isNotEmpty
                      ? Image.network(
                    widget.restaurant['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.orange,
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 100, color: Colors.white),
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.orange,
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 100, color: Colors.white),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant Info Card (floating)
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Rating and Basic Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoChip(
                              Icons.star,
                              widget.restaurant['rating']?.toString() ?? 'New',
                              Colors.orange,
                            ),
                            _buildInfoChip(
                              Icons.access_time,
                              widget.restaurant['delivery_time'] != null
                                  ? '${widget.restaurant['delivery_time']} min'
                                  : '30-45 min',
                              Colors.blue,
                            ),
                            _buildInfoChip(
                              Icons.motorcycle,
                              widget.restaurant['delivery_fee'] != null
                                  ? '₱${widget.restaurant['delivery_fee']}'
                                  : '₱0',
                              Colors.green,
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Opening Hours & Min Order
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              (widget.restaurant['is_open'] ?? true)
                                  ? 'Open Now • Closes 10:00 PM'
                                  : 'Currently Closed',
                              style: TextStyle(
                                color: (widget.restaurant['is_open'] ?? true)
                                    ? Colors.green[700]
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.receipt, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Min: ₱${widget.restaurant['min_order_amount'] ?? 100}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Menu', 0),
                    _buildTabButton('Info', 1),
                    _buildTabButton('Reviews', 2),
                  ],
                ),
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: _buildTabContent(),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(
                    restaurantId: widget.restaurant['id'],
                    restaurantName: widget.restaurant['resname'] ?? 'Restaurant',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View Full Menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.orange : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildMenuTab();
      case 1:
        return _buildInfoTab();
      case 2:
        return _buildReviewsTab();
      default:
        return _buildMenuTab();
    }
  }

  Widget _buildMenuTab() {
    if (_isLoadingMenu) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Loading menu...'),
          ],
        ),
      );
    }

    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No menu items available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigate to full menu page even if preview is empty
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(
                      restaurantId: widget.restaurant['id'],
                      restaurantName: widget.restaurant['resname'] ?? 'Restaurant',
                    ),
                  ),
                );
              },
              child: const Text('Browse Full Menu'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item['image_url'] != null &&
                    item['image_url'].toString().isNotEmpty
                    ? Image.network(
                  item['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 14),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? item['itemname'] ?? 'Menu Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  if ((item['description'] ?? item['itemdesc'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Text(
                      item['description'] ?? item['itemdesc'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  const SizedBox(height: 6),

                  // Halal/Non-Halal badge (if your items have this field)
                  if (item['ishalal'] != null)
                    Text(
                      item['ishalal'] == true ? 'Halal' : 'Non-Halal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item['ishalal'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],
              ),
            ),

            // Price and Add Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${(item['price'] ?? item['itemprice'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: item['is_available'] != false
                      ? () => _addToCart(item)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.orange.shade100,
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.orange, size: 40),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (widget.restaurant['description'] != null &&
              widget.restaurant['description'].toString().isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.restaurant['description'],
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],

          // Address
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text('Delivery Address'),
              subtitle: Text(widget.restaurant['address'] ?? '123 Food Street, Manila'),
              onTap: () {
                // TODO: Open maps
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maps integration coming soon!')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Business Hours
          const Text(
            'Business Hours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildHourRow('Monday - Friday', '10:00 AM - 10:00 PM'),
                _buildHourRow('Saturday', '11:00 AM - 11:00 PM'),
                _buildHourRow('Sunday', '11:00 AM - 9:00 PM'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          const Text(
            'Contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.orange),
                  title: const Text('Phone'),
                  subtitle: Text(widget.restaurant['phone'] ?? '+63 912 345 6789'),
                  onTap: () {
                    // TODO: Implement phone call
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone call feature coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.orange),
                  title: const Text('Email'),
                  subtitle: Text(widget.restaurant['email'] ?? 'restaurant@foodapp.com'),
                  onTap: () {
                    // TODO: Implement email
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(hours, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // TODO: Add review functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review feature coming soon!')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Write a Review'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    // TODO: Integrate with your cart system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item['name']} to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}