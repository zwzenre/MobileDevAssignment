import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Restaurants
  Future<List<dynamic>> getRestaurants() async {
    final response = await supabase.from('Restaurant').select();
    return List<dynamic>.from(response);
  }

  // Categories
  Future<List<dynamic>> getCategories() async {
    final response = await supabase.from('Category').select();
    return List<dynamic>.from(response);
  }

  // Items
  Future<List<dynamic>> getItems() async {
    final response = await supabase.from('Item').select();
    return List<dynamic>.from(response);
  }


  // Login
  Future<void> signIn(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception("Login failed");
    }
  }

  // Sign Up
  Future<void> signUp(String email, String password) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception("User already exists or signup failed");
    }

    final existing = await supabase
        .from('User')
        .select()
        .eq('userid', user.id);

    if (existing.isEmpty) {
      await supabase.from('User').insert({
        'userid': user.id,
        'email': email,
        'username': email.split('@')[0],
      });
    }
  }
}