import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

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
      final result = await _chatApi.getMessages(maChat: widget.maChat, limit: 50);
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              localizations.supportChat,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              localizations.noMessages,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadMessages(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message, theme);
                          },
                        ),
                      ),
          ),
          _buildMessageInput(localizations, theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, ThemeData theme) {
    final isFromAdmin = message.isFromAdmin;
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final messageDate = message.ngayGui;
    final isToday = messageDate.year == now.year && 
                    messageDate.month == now.month && 
                    messageDate.day == now.day;
    
    // Tính thời gian phản hồi nếu đây là tin nhắn từ admin (phản hồi)
    String? responseTimeText;
    if (isFromAdmin && _messages.isNotEmpty) {
      // Tìm tin nhắn user gần nhất trước tin nhắn này
      final messageIndex = _messages.indexOf(message);
      if (messageIndex > 0) {
        for (int i = messageIndex - 1; i >= 0; i--) {
          if (_messages[i].isFromUser) {
            final userMessageTime = _messages[i].ngayGui;
            final responseTime = messageDate.difference(userMessageTime);
            if (responseTime.inSeconds < 60) {
              responseTimeText = '${responseTime.inSeconds}s';
            } else if (responseTime.inMinutes < 60) {
              responseTimeText = '${responseTime.inMinutes} phút';
            } else if (responseTime.inHours < 24) {
              responseTimeText = '${responseTime.inHours} giờ';
            } else {
              responseTimeText = '${responseTime.inDays} ngày';
            }
            break;
          }
        }
      }
    }

    return Align(
      alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisAlignment:
              isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isFromAdmin) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFromAdmin
                      ? theme.primaryColor
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isFromAdmin ? const Radius.circular(4) : null,
                    bottomLeft: !isFromAdmin ? const Radius.circular(4) : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageContent(message.noiDung, isFromAdmin, theme),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isToday 
                              ? timeFormat.format(messageDate)
                              : '${dateFormat.format(messageDate)} ${timeFormat.format(messageDate)}',
                          style: TextStyle(
                            color: isFromAdmin
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (responseTimeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFromAdmin 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⏱️ $responseTimeText',
                              style: TextStyle(
                                color: isFromAdmin
                                    ? Colors.white
                                    : Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isFromAdmin) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.support_agent,
                  size: 16,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Parse message và hiển thị hình ảnh sản phẩm nếu có [PRODUCTS_DATA]
  Widget _buildMessageContent(String messageText, bool isFromAdmin, ThemeData theme) {
    // Kiểm tra tag [PRODUCTS_DATA]
    final productsDataMatch =
        RegExp(r'\[PRODUCTS_DATA\](.*?)\[/PRODUCTS_DATA\]', dotAll: true)
            .firstMatch(messageText);

    if (productsDataMatch != null) {
      try {
        // Phần text trước PRODUCTS_DATA
        final textMessage =
            messageText.substring(0, productsDataMatch.start).trim();
        final jsonStr = productsDataMatch.group(1)?.trim() ?? '';

        final productsData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final products = productsData['products'] as List<dynamic>? ?? [];

        final productsWithImages = products.where((p) {
          final imageData = (p as Map<String, dynamic>)['imageData'] as String?;
          return imageData != null && imageData.isNotEmpty;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (textMessage.isNotEmpty)
              Text(
                textMessage,
                style: TextStyle(
                  color: isFromAdmin
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            if (productsWithImages.isNotEmpty) ...[
              if (textMessage.isNotEmpty) const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productsWithImages.map((product) {
                  final p = product as Map<String, dynamic>;
                  final imageData = p['imageData'] as String?;

                  if (imageData != null && imageData.isNotEmpty) {
                    try {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(imageData),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } catch (_) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey.shade200,
                        child:
                            const Icon(Icons.image, color: Colors.grey),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ],
          ],
        );
      } catch (_) {
        // Nếu lỗi parse, hiển thị text bình thường
      }
    }

    // Mặc định: hiển thị text bình thường
    return Text(
      messageText,
      style: TextStyle(
        color: isFromAdmin
            ? Colors.white
            : theme.textTheme.bodyLarge?.color,
        fontSize: 15,
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  hintText: localizations.typeMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

