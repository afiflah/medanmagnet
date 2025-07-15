import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_page.dart';
import '../components/sidebar.dart'; // ✅ Tambahkan ini

class ChatAdminPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const ChatAdminPage({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ChatAdminPage> createState() => _ChatAdminPageState();
}

class _ChatAdminPageState extends State<ChatAdminPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> userChats = [];

  @override
  void initState() {
    super.initState();
    fetchUserChats();
  }

  Future<void> fetchUserChats() async {
    try {
      final users = await _supabase
          .from('users')
          .select('user_id, username')
          .eq('role', 'user');

      final messages = await _supabase
          .from('chat_messages')
          .select()
          .or('sender_id.eq.${widget.userId},receiver_id.eq.${widget.userId}')
          .order('timestamp', ascending: false);

      final result = users.map<Map<String, dynamic>>((user) {
        final userId = user['user_id'];
        final username = user['username'];

        final lastMsg = messages.firstWhere(
          (msg) =>
              msg['sender_id'] == userId || msg['receiver_id'] == userId,
          orElse: () => <String, dynamic>{},
        );

        return {
          'user_id': userId,
          'username': username,
          'last_message': lastMsg['message'] ?? '',
        };
      }).toList();

      setState(() {
        userChats = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chats: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat dengan Pengguna')),
      drawer: AdminSidebar( // ✅ Tambahkan drawer di sini
        userId: widget.userId,
        userRole: widget.userRole,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userChats.isEmpty
              ? const Center(child: Text('Belum ada pengguna.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userChats.length,
                  itemBuilder: (context, index) {
                    final chat = userChats[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(chat['username']),
                      subtitle: Text(
                        chat['last_message'].isEmpty
                            ? 'Belum ada pesan'
                            : chat['last_message'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(
                              userId: widget.userId,
                              userRole: widget.userRole,
                              targetUserId: chat['user_id'],
                              targetUsername: chat['username'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
