import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> getRestaurants() async {
    final response = await supabase
        .from('restaurant')
        .select();

    return response;
  }

  Future<List<dynamic>> getCategories() async {
    final response = await supabase
        .from('category')
        .select();

    return response;
  }

  Future<List<dynamic>> getItems() async {
    final response = await supabase
        .from('item')
        .select();

    return response;
  }
}