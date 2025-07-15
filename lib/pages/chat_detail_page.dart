import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final String userId;
  final String userRole;
  final String targetUserId;
  final String targetUsername;

  const ChatDetailPage({
    super.key,
    required this.userId,
    required this.userRole,
    required this.targetUserId,
    required this.targetUsername,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh UI setiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _supabase.from('chat_messages').insert({
        'sender_id': widget.userId,
        'receiver_id': widget.targetUserId,
        'message': text,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      _messageController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan')),
      );
    }
  }

  Future<void> _markMessagesAsRead(List<Map<String, dynamic>> messages) async {
    final unreadIds = messages
        .where((msg) =>
            msg['receiver_id'] == widget.userId &&
            msg['sender_id'] == widget.targetUserId &&
            msg['is_read'] == false)
        .map((msg) => msg['id'].toString())
        .toList();

    if (unreadIds.isEmpty) return;

    final condition = unreadIds.map((id) => 'id.eq.$id').join(',');

    try {
      await _supabase.from('chat_messages').update({'is_read': true}).or(condition);
    } catch (e) {
      debugPrint('Failed to update is_read: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _chatStream() {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('timestamp')
        .map((messages) {
          final filtered = messages.where((msg) {
            final sender = msg['sender_id'];
            final receiver = msg['receiver_id'];
            return (sender == widget.userId && receiver == widget.targetUserId) ||
                   (sender == widget.targetUserId && receiver == widget.userId);
          }).toList();

          _markMessagesAsRead(filtered);
          return filtered;
        });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isSender = msg['sender_id'] == widget.userId;
    final messageText = msg['message'] ?? '';
    final timestamp = DateTime.tryParse(msg['timestamp'] ?? '');
    final formattedTime = timestamp != null ? DateFormat('HH:mm').format(timestamp) : '';

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSender ? Colors.blue[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(messageText),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    if (isSender)
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Icon(
                          msg['is_read'] == true ? Icons.done_all : Icons.check,
                          size: 14,
                          color: msg['is_read'] == true ? Colors.blue : Colors.black45,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Tulis pesan...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat dengan ${widget.targetUsername}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan.'));
                }

                final messages = snapshot.data ?? [];

                // Scroll otomatis ke bawah
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
