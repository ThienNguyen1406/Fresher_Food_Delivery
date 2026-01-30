import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'dart:async';
import 'widgets/admin_chat_app_bar.dart';
import 'widgets/admin_empty_messages.dart';
import 'widgets/admin_message_input.dart';
import 'widgets/admin_message_bubble.dart';

class AdminChatDetailPage extends StatefulWidget {
  final String maChat;
  final String currentAdminId;
  final String userName;

  const AdminChatDetailPage({
    super.key,
    required this.maChat,
    required this.currentAdminId,
    required this.userName,
  });

  @override
  State<AdminChatDetailPage> createState() => _AdminChatDetailPageState();
}

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  final ChatApi _chatApi = ChatApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Auto refresh every 5 seconds để giảm tải (tăng từ 3 lên 5 giây)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 🔥 TỐI ƯU: Giảm limit từ 50 xuống 5 để load nhanh hơn
      final result =
          await _chatApi.getMessages(maChat: widget.maChat, limit: 5);
      final messages = result['messages'] as List<Message>;

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Mark as read
        await _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentAdminId,
        );

        // Scroll to bottom
        if (_messages.isNotEmpty && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: widget.currentAdminId,
        loaiNguoiGui: 'Admin',
        noiDung: text,
      );

      if (success && mounted) {
        _messageController.clear();
        _loadMessages(silent: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AdminChatAppBar(
        userName: widget.userName,
        theme: theme,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const AdminEmptyMessages()
                    : RefreshIndicator(
                        onRefresh: () => _loadMessages(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return AdminMessageBubble(
                              message: message,
                              allMessages: _messages,
                              theme: theme,
                            );
                          },
                        ),
                      ),
          ),
          AdminMessageInput(
            messageController: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
            theme: theme,
          ),
        ],
      ),
    );
  }
}
