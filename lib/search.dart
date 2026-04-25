import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    fetchData(); // load data
  }

  @override
  void dispose() {
    searchController.dispose(); // clean up
    super.dispose();
  }

  // fetch items + categories
  Future<void> fetchData() async {
    try {
      final itemData = await supabase.from('Item').select();
      final catData = await supabase.from('Category').select();

      setState(() {
        items = itemData;
        categories = catData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // filter logic
  List filteredItems() {
    Map<String, dynamic>? selectedCat;

    try {
      selectedCat = categories.firstWhere(
            (c) => c['categoryname'] == selectedCategory,
      );
    } catch (e) {
      selectedCat = null;
    }

    return items.where((item) {
      final name = item['itemname'].toString().toLowerCase();

      final matchSearch = name.contains(searchText.toLowerCase());

      final matchCategory = selectedCategory == "All" ||
          (selectedCat != null &&
              item['categoryid'] == selectedCat['categoryid']);

      return matchSearch && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),

      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.orange,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // search bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() => searchText = value);
              },
              decoration: InputDecoration(
                hintText: "Search food...",
                prefixIcon: const Icon(Icons.search),

                // clear
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = "");
                  },
                )
                    : null,

                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // category chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip("All"),
                ...categories.map((cat) {
                  return _chip(cat['categoryname']);
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // results
          Expanded(
            child: results.isEmpty
                ? const Center(
              child: Text(
                "No items found",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item['image_url'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,

                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          );
                        },

                        // fallback
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fastfood, color: Colors.orange),
                          );
                        },
                      )
                    ),
                    title: Text(item['itemname']),
                    subtitle:
                    Text(item['itemdesc'] ?? ''),
                    trailing: Text(
                      "RM ${double.parse(item['itemprice'].toString()).toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // reusable chip
  Widget _chip(String label) {
    final isSelected = selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.orange,
        onSelected: (_) {
          setState(() => selectedCategory = label);
        },
      ),
    );
  }
}