import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// Import Message class
import 'package:fresher_food/models/Chat.dart' show Message;

/// Chat interface cho admin RAG (giống ChatGPT)
class AdminRagChatPage extends StatefulWidget {
  final String maChat;
  final String currentUserId;

  const AdminRagChatPage({
    super.key,
    required this.maChat,
    required this.currentUserId,
  });

  @override
  State<AdminRagChatPage> createState() => _AdminRagChatPageState();
}

class _AdminRagChatPageState extends State<AdminRagChatPage> {
  final ChatApi _chatApi = ChatApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Chat? _chatInfo;
  Timer? _refreshTimer;
  bool _isWaitingForBotResponse = false;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
    _loadMessages();
    // Auto refresh every 5 seconds để giảm tải (tăng từ 2 lên 5 giây)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isSending && !_isWaitingForBotResponse && mounted) {
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

  Future<void> _loadChatInfo() async {
    try {
      final chats = await _chatApi.getUserChats(widget.currentUserId);
      final chat = chats.firstWhere(
        (c) => c.maChat == widget.maChat,
        orElse: () => Chat(
          maChat: widget.maChat,
          maNguoiDung: widget.currentUserId,
          trangThai: 'Open',
          ngayTao: DateTime.now(),
        ),
      );
      setState(() {
        _chatInfo = chat;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _chatApi.getMessages(maChat: widget.maChat, limit: 50);
      final messages = result['messages'] as List<Message>;
      
      // Check if there are new messages
      final hasNewMessages = messages.length != _messages.length || 
          (messages.isNotEmpty && _messages.isNotEmpty && 
           messages.last.maTinNhan != _messages.last.maTinNhan);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
        // If bot responded, stop waiting
        if (hasNewMessages && _isWaitingForBotResponse) {
          final lastMessage = messages.isNotEmpty ? messages.last : null;
          if (lastMessage != null && lastMessage.loaiNguoiGui == 'Admin') {
            _isWaitingForBotResponse = false;
          }
        }
      });

      // Mark messages as read when admin views the conversation
      if (!silent) {
        await _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentUserId,
        );
      }

      // Auto scroll to bottom if there are new messages
      if (hasNewMessages) {
        _scrollToBottom();
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _isWaitingForBotResponse = true;
    });

    try {
      // Gửi tin nhắn user
      // Backend sẽ tự động xử lý RAG và trả lời (không cần gọi askWithDocument riêng)
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: widget.currentUserId,
        loaiNguoiGui: 'User',
        noiDung: text,
      );

      _messageController.clear();
      
      // Reload messages ngay để hiển thị tin nhắn user
      await _loadMessages();
      
      // Backend sẽ tự động trả lời sau 2 giây
      // Auto-refresh timer sẽ tự động check và load tin nhắn bot mới
      // Đợi tối đa 8 giây để bot trả lời (giảm từ 10 xuống 8)
      int waitCount = 0;
      while (_isWaitingForBotResponse && waitCount < 8 && mounted) {
        await Future.delayed(const Duration(milliseconds: 1500)); // Tăng từ 1s lên 1.5s
        waitCount++;
        // Check if bot has responded
        if (mounted) {
          await _loadMessages(silent: true);
        }
      }
      
      // Final reload to ensure we have the latest messages
      if (mounted) {
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi tin nhắn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
        _isWaitingForBotResponse = false;
      });
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chatInfo?.tieuDe ?? 'Tìm kiếm thông tin',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (_chatInfo?.ngayTao != null)
              Text(
                'Tạo lúc ${_formatTime(_chatInfo!.ngayTao)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadMessages,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.message_question,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có tin nhắn nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu trò chuyện với bot',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message.loaiNguoiGui == 'User';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.green.shade100,
                                    child: Icon(
                                      Iconsax.message_text,
                                      size: 18,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Colors.green
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.noiDung,
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                            color: isUser
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(message.ngayGui),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUser
                                                ? Colors.white70
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Icon(
                                      Iconsax.user,
                                      size: 18,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Iconsax.send_1,
                              color: Colors.white,
                            ),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

