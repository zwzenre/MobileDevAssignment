import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile.dart';
import 'login.dart';
import 'order_history.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser(); // load user data
  }

  Future<void> fetchUser() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final data = await supabase
            .from('User')
            .select()
            .eq('userid', user.id)
            .single();

        setState(() {
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut(); // logout user

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        userData?['username'] ??
                            user?.email?.split('@')[0] ??
                            "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // user info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      infoTile(Icons.email, user?.email ?? "No Email"),
                      infoTile(
                        Icons.person,
                        userData?['username'] ?? "No Username",
                      ),
                      infoTile(Icons.phone, userData?['phone'] ?? "No Phone"),
                      infoTile(
                        Icons.location_on,
                        userData?['address'] ?? "No Address",
                      ),

                      const SizedBox(height: 30),

                      // order history
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderHistory(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Order History"),
                      ),

                      const SizedBox(height: 15),

                      // edit button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfile(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Edit Profile"),
                      ),

                      const SizedBox(height: 15),

                      // logout button
                      OutlinedButton(
                        onPressed: logout,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // reusable tile
  Widget infoTile(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 15),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
