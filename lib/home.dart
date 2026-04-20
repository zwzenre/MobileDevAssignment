import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final supabase = Supabase.instance.client;

  List<dynamic> restaurants = [];
  List<dynamic> categories = [];
  List<dynamic> items = [];

  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final res = await supabase.from('restaurant').select();
    final cat = await supabase.from('category').select();
    final itm = await supabase.from('item').select();

    setState(() {
      restaurants = res;
      categories = cat;
      items = itm;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "What you want to eat today",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            // Promo Banner
            SizedBox(
              height: 150,
              child: PageView(
                children: [
                  _promoCard(Colors.orange),
                  _promoCard(Colors.red),
                  _promoCard(Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Categories
            _sectionTitle("Categories"),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) {
                  return _categoryItem(cat['categoryname'] ?? 'No Name');
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Restaurants
            _sectionTitle("Nearby Restaurants"),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.8,
              children: restaurants.map((res) {
                return _restaurantCard(
                  res['resname'] ?? 'No Name',
                  res['rating']?.toString() ?? '0.0',
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Popular Cuisine
            _sectionTitle("Popular Cuisine"),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items.map((item) {
                return _foodItem(
                  item['itemname'] ?? 'No Name',
                  "RM${item['itemprice'] ?? '0'}",
                );
              }).toList(),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  // ================= UI WIDGETS =================

  Widget _promoCard(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _categoryItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }

  Widget _restaurantCard(String name, String rating) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Container(color: Colors.grey[300]),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 5),
                    Text(rating),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _foodItem(String name, String price) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        color: Colors.grey[300],
      ),
      title: Text(name),
      trailing: Text(price),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text("See more"),
        ],
      ),
    );
  }
}