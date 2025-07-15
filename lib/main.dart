import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ukegwfwzuytgbcoizjjv.supabase.co', // GANTI
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrZWd3Znd6dXl0Z2Jjb2l6amp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5NjU0NDMsImV4cCI6MjA2NzU0MTQ0M30.X1SVRuvhxOD73GSXApeqW9_JBWnOfidh7Dw4GGPfK_Q', 
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth Demo',
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}

