import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'restaurant_details_page.dart';

class AllRestaurantsPage extends StatefulWidget {
  final dynamic categoryId;
  final String categoryName;

  const AllRestaurantsPage({
    super.key,
    this.categoryId,
    this.categoryName = 'Restaurants'
  });

  @override
  State<AllRestaurantsPage> createState() => _AllRestaurantsPageState();
}

class _AllRestaurantsPageState extends State<AllRestaurantsPage> {
  final SupabaseService _service = SupabaseService();
  List<dynamic> _restaurants = [];
  List<dynamic> _filteredRestaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'Rating';

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      if (widget.categoryId != null) {
        final data = await _service.getRestaurantsByCategory(widget.categoryId);

        setState(() {
          _restaurants = data;
          _filteredRestaurants = data;
          _isLoading = false;
        });
      } else {
        final allRestaurants = await _service.getRestaurants();

        setState(() {
          _restaurants = allRestaurants;
          _filteredRestaurants = allRestaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load restaurants: $e');
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      _searchQuery = query;
      _filteredRestaurants = _restaurants.where((restaurant) {
        final name = restaurant['resname']?.toLowerCase() ?? '';
        final description = restaurant['description']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _sortRestaurants() {
    setState(() {
      switch (_sortBy) {
        case 'Rating':
          _filteredRestaurants.sort((a, b) =>
              (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
          break;
        case 'Delivery Time':
          _filteredRestaurants.sort((a, b) =>
              (a['delivery_time'] ?? 999).compareTo(b['delivery_time'] ?? 999));
          break;
        case 'Price (Low to High)':
          _filteredRestaurants.sort((a, b) =>
              (a['delivery_fee'] ?? 0).compareTo(b['delivery_fee'] ?? 0));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _filterRestaurants(''),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0), // Added to reduce height
              ),
              onChanged: _filterRestaurants,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _filteredRestaurants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No restaurants match "$_searchQuery"'
                  : 'No restaurants found in this category',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _filterRestaurants(''),
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      )
          : Column(
        children: [
          // Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredRestaurants.length} restaurants found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Row(
                  children: [
                    const Icon(Icons.sort, size: 18),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Rating', child: Text('Rating ↓', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Delivery Time', child: Text('Fastest', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Price (Low to High)', child: Text('Price ↓', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (value) {
                        setState(() => _sortBy = value!);
                        _sortRestaurants();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12), // Reduced padding
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _filteredRestaurants[index];
                return _buildRestaurantCard(context, restaurant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Map<String, dynamic> restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      elevation: 3, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsPage(
                restaurant: restaurant,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: restaurant['image_url'] != null && restaurant['image_url'].toString().isNotEmpty
                  ? Image.network(
                restaurant['image_url'],
                height: 150, // Reduced from 180
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.orange[100],
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 40, color: Colors.orange),
                  ),
                ),
              )
                  : Container(
                height: 150,
                color: Colors.orange[100],
                child: const Center(
                  child: Icon(Icons.restaurant, size: 40, color: Colors.orange),
                ),
              ),
            ),

            // Restaurant Info
            Padding(
              padding: const EdgeInsets.all(10), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['resname'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16, // Reduced from 18
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant['rating'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                restaurant['rating'].toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  if (restaurant['description'] != null && restaurant['description'].toString().isNotEmpty)
                    Text(
                      restaurant['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1, // Reduced from 2
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      if (restaurant['delivery_time'] != null) ...[
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${restaurant['delivery_time']} min', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                      ],

                      if (restaurant['delivery_fee'] != null) ...[
                        Icon(Icons.motorcycle, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('₱${restaurant['delivery_fee']}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                      ],

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (restaurant['is_open'] ?? true) ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (restaurant['is_open'] ?? true) ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 10,
                            color: (restaurant['is_open'] ?? true) ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}