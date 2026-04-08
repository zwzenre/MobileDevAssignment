import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://urjdpdhzmqaetquydrhj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyamRwZGh6bXFhZXRxdXlkcmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NjcwNjgsImV4cCI6MjA5MTE0MzA2OH0.MhDW8yuKQbLmzOngI0DfQEhCf2neqvcf1A7eBGE4LFw',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}
