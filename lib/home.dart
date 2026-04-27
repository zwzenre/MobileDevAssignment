import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'search.dart';
import 'all_categories.dart';
import 'all_restaurants.dart';
import 'all_items.dart';
import 'restaurant_details_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final service = SupabaseService();

  late Future<List<dynamic>> restaurants;
  late Future<List<dynamic>> categories;
  late Future<List<dynamic>> items;

  @override
  void initState() {
    super.initState();
    restaurants = service.getRestaurants();
    categories = service.getCategories();
    items = service.getItems();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Food App"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildBanner(),

            _buildSectionHeader('Categories', const AllCategoriesPage()),
            _buildCategories(),

            _buildSectionHeader('Nearby Restaurants', const AllRestaurantsPage()),
            _buildRestaurants(),

            _buildSectionHeader('Popular Items', const AllItemsPage()),
            _buildItems(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: "What do you want to eat?",
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WEEKLY SPECIAL OFFER',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '50% OFF',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Widget page) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              )),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: Text(
              'See more',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return FutureBuilder<List<dynamic>>(
      future: categories,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final c = data[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllItemsPage(
                        categoryId: c['categoryid'],
                        categoryName: c['categoryname'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: c['image_url'] != null && c['image_url'].toString().isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: c['image_url'],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _boxIcon(),
                        )
                            : _boxIcon(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c['categoryname'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurants() {
    return FutureBuilder<List<dynamic>>(
      future: restaurants,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final r = data[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailsPage(
                        restaurant: r,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        r['image_url'] != null && r['image_url'].toString().isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: r['image_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _imgPlaceholder(),
                        )
                            : _imgPlaceholder(),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            r['resname'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItems() {
    return FutureBuilder<List<dynamic>>(
      future: items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final i = data[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () async {
                  final resList = await restaurants;

                  final restaurant = resList.firstWhere(
                        (r) =>
                    r['resid'] == i['resid'] ||
                        r['id'] == i['restaurant_id'],
                    orElse: () => null,
                  );

                  if (restaurant != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailsPage(
                          restaurant: restaurant,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('restaurant not found')),
                    );
                  }
                },

                leading: i['image_url'] != null &&
                    i['image_url'].toString().isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: i['image_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _boxIcon(),
                )
                    : _boxIcon(),

                title: Text(i['itemname'] ?? ''),
                subtitle: Text(i['itemdesc'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  Widget _boxIcon() {
    final theme = Theme.of(context);

    return Container(
      width: 60,
      height: 60,
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.fastfood,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _imgPlaceholder() {
    final theme = Theme.of(context);

    return Container(
      height: 100,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}