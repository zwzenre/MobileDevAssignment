import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final supabase = Supabase.instance.client;

  List promos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPromos();
  }

  Future<void> fetchPromos() async {
    try {
      final data = await supabase
          .from('promotion')
          .select()
          .eq('is_active', true);

      print(data);

      setState(() {
        promos = data;
      });
    } catch (e) {
      print("Promo error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Promotions"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      )
          : promos.isEmpty
          ? const Center(child: Text("No promotions available"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          return _buildPromoCard(promo, theme);
        },
      ),
    );
  }

  Widget _buildPromoCard(Map promo, ThemeData theme) {
    final code = promo['code'] ?? '';
    final desc = promo['description'] ?? '';
    final type = promo['discount_type'];
    final value = promo['discount_value'];
    final endDate = promo['end_date'];

    String discountText = '';

    if (type == 'percentage') {
      discountText = "$value% OFF";
    } else {
      discountText = "RM $value OFF";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // fixed layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                discountText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // description
            Text(
              desc,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 10),

            // expiry
            if (endDate != null)
              Text(
                "Valid until: ${endDate.toString().substring(0, 10)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),

            const SizedBox(height: 12),

            // button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, promo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Use Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}