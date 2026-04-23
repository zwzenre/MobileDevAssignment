import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final supabase = Supabase.instance.client;

  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser(); // load existing data
  }

  Future<void> loadUser() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final data = await supabase
          .from('User')
          .select()
          .eq('userid', user.id)
          .maybeSingle();

      if (data != null) {
        usernameController.text = data['username'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase.from('User').update({
      'username': usernameController.text,
      'phone': phoneController.text,
      'address': addressController.text,
    }).eq('userid', user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );

    Navigator.pop(context); // go back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}