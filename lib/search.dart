import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'restaurant_details_page.dart';

class SearchPage extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const SearchPage({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController searchController = TextEditingController();

  List items = [];
  List categories = [];
  List restaurants = [];

  String searchText = "";
  String selectedCategory = "All";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final itemData = await supabase
          .from('item')
          .select('*, restaurant(*)');

      final categoryData = await supabase.from('category').select();

      final restaurantData = await supabase.from('restaurant').select();

      setState(() {
        items = itemData;
        categories = categoryData;
        restaurants = restaurantData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  // filter items
  List get filteredItems {
    return items.where((item) {
      final name = item['itemname']?.toLowerCase() ?? '';
      final matchesSearch = name.contains(searchText.toLowerCase());

      if (selectedCategory == "All") return matchesSearch;

      final category = categories.where(
            (c) => c['categoryid'] == item['categoryid'],
      ).toList();

      final categoryName =
      category.isNotEmpty ? category.first['categoryname'] : '';

      return matchesSearch && categoryName == selectedCategory;
    }).toList();
  }

  // filter restaurants
  List get filteredRestaurants {
    return restaurants.where((r) {
      final name = r['resname']?.toLowerCase() ?? '';
      return name.contains(searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ??
                  () {
                Navigator.of(context).maybePop();
              },
        )
            : null,
        title: const Text("Search"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search food or restaurant...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // category filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildCategoryChip("All"),
                ...categories.map((c) {
                  return _buildCategoryChip(c['categoryname']);
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: (filteredItems.isEmpty &&
                filteredRestaurants.isEmpty)
                ? Center(
              child: Text(
                "No results found",
                style: TextStyle(color: theme.hintColor),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // restaurants section
                if (filteredRestaurants.isNotEmpty) ...[
                  const Text(
                    "Restaurants",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filteredRestaurants
                      .map((r) => _buildRestaurantCard(r))
                      .toList(),
                  const SizedBox(height: 20),
                ],

                // items section
                if (filteredItems.isNotEmpty) ...[
                  const Text(
                    "Items",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filteredItems
                      .map((i) => _buildItemCard(i))
                      .toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name) {
    final theme = Theme.of(context);
    final isSelected = selectedCategory == name;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.textTheme.bodyMedium?.color,
        ),
        onSelected: (_) {
          setState(() {
            selectedCategory = name;
          });
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Map r) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsPage(
                restaurant: {
                  ...r,
                  'id': r['resid'],
                },
              ),
            ),
          );
        },
        leading: r['image_url'] != null &&
            r['image_url'].toString().isNotEmpty
            ? CachedNetworkImage(
          imageUrl: r['image_url'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(),
        )
            : _placeholder(),
        title: Text(r['resname'] ?? ''),
        subtitle: const Text("Restaurant"),
      ),
    );
  }

  Widget _buildItemCard(Map item) {
    final theme = Theme.of(context);
    final restaurant = item['restaurant'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          if (restaurant == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsPage(
                restaurant: {
                  ...restaurant,
                  'id': restaurant['resid'],
                },
              ),
            ),
          );
        },
        leading: item['image_url'] != null &&
            item['image_url'].toString().isNotEmpty
            ? CachedNetworkImage(
          imageUrl: item['image_url'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(),
        )
            : _placeholder(),
        title: Text(item['itemname'] ?? ''),
        subtitle: Text(restaurant?['resname'] ?? ''),
        trailing: Text(
          'RM ${(item['itemprice'] ?? 0).toDouble().toStringAsFixed(2)}',
        ),
      ),
    );
  }

  Widget _placeholder() {
    final theme = Theme.of(context);

    return Container(
      width: 60,
      height: 60,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.fastfood,
        color: theme.colorScheme.primary,
      ),
    );
  }
}