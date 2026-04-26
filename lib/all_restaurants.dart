import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'restaurant_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterRestaurants,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : _filteredRestaurants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No restaurants match "$_searchQuery"'
                  : 'No restaurants found',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredRestaurants.length} restaurants found',
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                Row(
                  children: [
                    const Icon(Icons.sort, size: 18),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Rating', child: Text('Rating ↓')),
                        DropdownMenuItem(value: 'Delivery Time', child: Text('Fastest')),
                        DropdownMenuItem(value: 'Price (Low to High)', child: Text('Price ↓')),
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
              padding: const EdgeInsets.all(12),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsPage(restaurant: restaurant),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: restaurant['image_url'] != null &&
                  restaurant['image_url'].toString().isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: restaurant['image_url'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _imgPlaceholder(context),
              )
                  : _imgPlaceholder(context),
            ),

            // info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['resname'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    restaurant['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 150,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.restaurant,
        color: theme.colorScheme.primary,
      ),
    );
  }

  void _showError(String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }
}