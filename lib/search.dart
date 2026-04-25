import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController searchController = TextEditingController();

  List items = [];
  List categories = [];

  String searchText = "";
  String selectedCategory = "All";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // fetch data
  Future<void> fetchData() async {
    try {
      final itemData = await supabase.from('item').select();
      final categoryData = await supabase.from('category').select();

      setState(() {
        items = itemData;
        categories = categoryData;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  // filter logic
  List get filteredItems {
    return items.where((item) {
      final name = item['itemname']?.toLowerCase() ?? '';
      final categoryId = item['categoryid'];

      final matchesSearch = name.contains(searchText.toLowerCase());

      if (selectedCategory == "All") {
        return matchesSearch;
      }

      final category = categories.firstWhere(
            (c) => c['categoryid'] == categoryId,
        orElse: () => null,
      );

      final categoryName = category?['categoryname'] ?? '';

      return matchesSearch && categoryName == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                hintText: "Search food...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
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

          // item list
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
              child: Text("No items found"),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // category chip
  Widget _buildCategoryChip(String name) {
    final isSelected = selectedCategory == name;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: Colors.orange,
        onSelected: (_) {
          setState(() {
            selectedCategory = name;
          });
        },
      ),
    );
  }

  // item card
  Widget _buildItemCard(Map item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item['image_url'] != null &&
            item['image_url'].toString().isNotEmpty
            ? CachedNetworkImage(
          imageUrl: item['image_url'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 60,
            height: 60,
            color: Colors.orange.shade100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => _placeholder(),
        )
            : _placeholder(),
        title: Text(item['itemname'] ?? ''),
        subtitle: Text(item['itemdesc'] ?? ''),
        trailing: Text(
          'RM ${(item['itemprice'] ?? 0).toDouble().toStringAsFixed(2)}',
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.orange.shade100,
      child: const Icon(Icons.fastfood, color: Colors.orange),
    );
  }
}