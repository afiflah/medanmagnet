import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_page.dart';

class ChatUserPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const ChatUserPage({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ChatUserPage> createState() => _ChatUserPageState();
}

class _ChatUserPageState extends State<ChatUserPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navigateToAdminChat();
  }

  Future<void> _navigateToAdminChat() async {
    try {
      // Ambil salah satu admin dari database
      final response = await _supabase
          .from('users')
          .select('user_id, username')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final adminId = response['user_id'];
        final adminUsername = response['username'];

        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailPage(
                userId: widget.userId,
                userRole: widget.userRole,
                targetUserId: adminId,
                targetUsername: adminUsername,
              ),
            ),
          );
        }
      } else {
        _showError('Admin tidak ditemukan.');
      }
    } catch (e) {
      _showError('Gagal mengambil data admin.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
