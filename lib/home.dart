import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'search.dart';
import 'all_categories.dart';
import 'all_restaurants.dart';
import 'all_items.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Food App")),
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
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WEEKLY SPECIAL OFFER',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '50% OFF',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: const Text('See more'),
          ),
        ],
      ),
    );
  }

  // =========================
  // CATEGORY (CLICKABLE)
  // =========================
  Widget _buildCategories() {
    return FutureBuilder<List<dynamic>>(
      future: categories,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()));
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
                        child: c['image_url'] != null
                            ? Image.network(
                          c['image_url'],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _boxIcon(),
                        )
                            : _boxIcon(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c['categoryname'] ?? '',
                        style: const TextStyle(fontSize: 12),
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

  // =========================
  // RESTAURANTS
  // =========================
  Widget _buildRestaurants() {
    return FutureBuilder<List<dynamic>>(
      future: restaurants,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 190, child: Center(child: CircularProgressIndicator()));
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
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      r['image_url'] != null
                          ? Image.network(
                        r['image_url'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                          : _imgPlaceholder(),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(r['resname'] ?? '',
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                      )
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

  // =========================
  // ITEMS
  // =========================
  Widget _buildItems() {
    return FutureBuilder<List<dynamic>>(
      future: items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()));
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
                leading: i['image_url'] != null
                    ? Image.network(
                  i['image_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _boxIcon(),
                )
                    : _boxIcon(),
                title: Text(i['itemname'] ?? ''),
                subtitle: Text(i['itemdesc'] ?? ''),
                trailing: Text(
                    'RM ${(i['itemprice'] ?? 0).toDouble().toStringAsFixed(2)}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _boxIcon() => Container(
    width: 60,
    height: 60,
    color: Colors.orange.shade100,
    child: const Icon(Icons.fastfood, color: Colors.orange),
  );

  Widget _imgPlaceholder() => Container(
    height: 100,
    color: Colors.orange.shade50,
    child: const Center(
        child: Icon(Icons.restaurant, color: Colors.orange)),
  );
}