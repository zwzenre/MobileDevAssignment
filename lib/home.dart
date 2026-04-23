import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'search.dart';

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
            _buildSectionHeader('Categories'),
            _buildCategories(),
            _buildSectionHeader('Nearby Restaurants'),
            _buildRestaurants(),
            _buildSectionHeader('Popular Items'),
            _buildItems(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Search()),
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

  // Promo Banner
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '50% OFF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // See More
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('See more'),
          ),
        ],
      ),
    );
  }

  // Categories
  Widget _buildCategories() {
    return FutureBuilder<List<dynamic>>(
      future: categories,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
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
              final category = data[index];
              return _CategoryCard(
                name: category['categoryname'] ?? '',
                imageUrl: category['categoryimage'] ?? '',
              );
            },
          ),
        );
      },
    );
  }

  // Restaurants
  Widget _buildRestaurants() {
    return FutureBuilder<List<dynamic>>(
      future: restaurants,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator()),
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
              final res = data[index];
              return _RestaurantCard(
                name: res['resname'] ?? '',
                address: res['resaddress'] ?? '',
                imageUrl: res['resimage'] ?? '',
                rating: (res['rating'] ?? 0).toDouble(),
                isHalal: res['ishalal'] ?? false,
                eta: res['eta'] ?? '~10mins',
              );
            },
          ),
        );
      },
    );
  }

  // Popular Items
  Widget _buildItems() {
    return FutureBuilder<List<dynamic>>(
      future: items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return _ItemTile(
              name: item['itemname'] ?? '',
              desc: item['itemdesc'] ?? '',
              imageUrl: item['itemimage'] ?? '',
              price: (item['itemprice'] ?? 0).toDouble(),
              isHalal: item['ishalal'] ?? false,
            );
          },
        );
      },
    );
  }
}

// Category Card
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    color: Colors.orange.shade100,
    child: const Icon(Icons.fastfood, color: Colors.orange),
  );
}

// Restaurant Card
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.isHalal,
    required this.eta,
  });

  final String name, address, imageUrl, eta;
  final double rating;
  final bool isHalal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
                : _imagePlaceholder(),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating + ETA
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        ' $rating  $eta',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Halal badge
                  Text(
                    isHalal ? 'Halal' : 'Non-Halal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isHalal ? Colors.green : Colors.red,
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

  Widget _imagePlaceholder() => Container(
    height: 100,
    color: Colors.orange.shade50,
    child: const Center(
      child: Icon(Icons.restaurant, size: 36, color: Colors.orange),
    ),
  );
}

// Item tile
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.name,
    required this.desc,
    required this.imageUrl,
    required this.price,
    required this.isHalal,
  });

  final String name, desc, imageUrl;
  final double price;
  final bool isHalal;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? Image.network(
            imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
              : _placeholder(),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.isNotEmpty)
              Text(
                desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 2),
            Text(
              isHalal ? 'Halal' : 'Non-Halal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isHalal ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: Text(
          'RM ${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60,
    height: 60,
    color: Colors.orange.shade50,
    child: const Icon(Icons.fastfood, color: Colors.orange),
  );
}