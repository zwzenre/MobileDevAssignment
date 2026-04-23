import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final supabase = Supabase.instance.client;

  List items = [];
  List categories = [];
  List filteredItems = [];

  String selectedCategory = "All";
  bool isLoading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData(); // load items + categories
  }

  Future<void> fetchData() async {
    try {
      final itemData = await supabase.from('item').select();
      final categoryData = await supabase.from('category').select();

      setState(() {
        items = itemData;
        categories = categoryData;
        filteredItems = itemData;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  void applyFilter() {
    final query = searchController.text.toLowerCase();

    final results = items.where((item) {
      final name = item['itemname'].toString().toLowerCase();

      final matchSearch = name.contains(query);

      final matchCategory = selectedCategory == "All"
          ? true
          : item['categoryid'].toString() ==
          categories
              .firstWhere((c) =>
          c['categoryname'] == selectedCategory)['categoryid']
              .toString();

      return matchSearch && matchCategory;
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [

          // search bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: searchController,
              onChanged: (value) => applyFilter(),
              decoration: InputDecoration(
                hintText: "Search food...",
                prefixIcon: const Icon(Icons.search),
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [

                // ALL chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: const Text("All"),
                    selected: selectedCategory == "All",
                    onSelected: (selected) {
                      setState(() => selectedCategory = "All");
                      applyFilter();
                    },
                    selectedColor: Colors.orange,
                  ),
                ),

                // dynamic categories
                ...categories.map((cat) {
                  final name = cat['categoryname'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: selectedCategory == name,
                      onSelected: (selected) {
                        setState(() => selectedCategory = name);
                        applyFilter();
                      },
                      selectedColor: Colors.orange,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // results
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                ? const Center(
              child: Text(
                "No results found",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(item['itemname']),
                    subtitle: Text(item['itemdesc'] ?? ''),
                    trailing: Text(
                      "RM ${item['itemprice']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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
}