import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Register
  Future<String?> register(String username, String email, String password) async {
    final response = await supabase.auth.signUp(email: email, password: password);
    final userId = response.user?.id;

    if (userId != null) {
      await supabase.from('users').insert({
        'id': userId,
        'username': username,
        'email': email, // Simpan email juga di tabel 'users'
      });
      return null; // success
    } else {
      return 'Failed to register.';
    }
  }

  // Login pakai email atau username
  Future<String?> login(String identifier, String password) async {
    try {
      String email = identifier;

      // Jika input bukan email, anggap username → cari email-nya di tabel 'users'
      if (!identifier.contains('@')) {
        final res = await supabase
            .from('users')
            .select('email')
            .eq('username', identifier)
            .single();

        // ignore: unnecessary_null_comparison
        if (res != null) {
          email = res['email'];
        } else {
          return 'Username not found';
        }
      }

      await supabase.auth.signInWithPassword(email: email, password: password);
      return null; // success
    } catch (e) {
      return 'Login failed: $e';
    }
  }
}
