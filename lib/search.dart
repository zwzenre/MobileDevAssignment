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

  // safer filter
  List get filteredItems {
    return items.where((item) {
      final name = item['itemname']?.toLowerCase() ?? '';
      final categoryId = item['categoryid'];

      final matchesSearch = name.contains(searchText.toLowerCase());

      if (selectedCategory == "All") return matchesSearch;

      final category = categories.where(
            (c) => c['categoryid'] == categoryId,
      ).toList();

      final categoryName =
      category.isNotEmpty ? category.first['categoryname'] : '';

      return matchesSearch && categoryName == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
                hintText: "Search food...",
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

          // items
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
              child: Text(
                "No items found",
                style: TextStyle(color: theme.hintColor),
              ),
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

  // chip
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

  // item card
  Widget _buildItemCard(Map item) {
    final theme = Theme.of(context);

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
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
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