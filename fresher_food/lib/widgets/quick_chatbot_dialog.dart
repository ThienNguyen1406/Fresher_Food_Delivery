import 'package:flutter/material.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/utils/constant.dart';
import 'dart:async';
import 'dart:convert';

/// Quick Chatbot Dialog - Hỏi đáp nhanh với RAG API
class QuickChatbotDialog extends StatefulWidget {
  const QuickChatbotDialog({super.key});

  @override
  State<QuickChatbotDialog> createState() => _QuickChatbotDialogState();
}

class _QuickChatbotDialogState extends State<QuickChatbotDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RagApi _ragApi = RagApi();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isWaitingForResponse = false;

  @override
  void initState() {
    super.initState();
    // Thêm tin nhắn chào mừng
    _messages.add(ChatMessage(
      text:
          'Xin chào! Tôi có thể giúp gì cho bạn? Hãy đặt câu hỏi về sản phẩm, đơn hàng, hoặc bất kỳ thông tin nào bạn cần.',
      isFromBot: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Thêm câu hỏi của user vào danh sách
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isFromBot: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _isWaitingForResponse = true;
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      // Gọi RAG API để lấy câu trả lời
      final response = await _ragApi.askWithDocument(
        question: question,
        fileId: null, // Không cần file cụ thể, tìm trong tất cả documents
        maChat: null, // Không cần chat, đây là quick chat
        baseUrl: Constant().baseUrl,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWaitingForResponse = false;
        });

        if (response != null && response['answer'] != null) {
          // Lấy danh sách ảnh sản phẩm nếu có
          final products = response['products'] as List<dynamic>? ?? [];
          final images = products
              .map((p) => (p as Map<String, dynamic>)['imageData'] as String?)
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toList();

          _messages.add(ChatMessage(
            text: response['answer'] as String,
            isFromBot: true,
            timestamp: DateTime.now(),
            imageDataList: images,
          ));
        } else {
          _messages.add(ChatMessage(
            text:
                'Xin lỗi, tôi không thể tìm thấy thông tin để trả lời câu hỏi này. Vui lòng thử lại hoặc liên hệ với tại phần Chat để được hỗ trợ!',
            isFromBot: true,
            timestamp: DateTime.now(),
          ));
        }

        setState(() {});
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWaitingForResponse = false;
        });
        _messages.add(ChatMessage(
          text: 'Đã xảy ra lỗi khi xử lý câu hỏi. Vui lòng thử lại sau.',
          isFromBot: true,
          timestamp: DateTime.now(),
        ));
        setState(() {});
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý ảo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hỏi đáp nhanh',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text('Bắt đầu cuộc trò chuyện...'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _messages.length + (_isWaitingForResponse ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isWaitingForResponse &&
                            index == _messages.length) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index], theme);
                      },
                    ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                                color: Colors.green.shade600, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendQuestion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade700
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isLoading ? null : _sendQuestion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isFromBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isFromBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isFromBot
                    ? null
                    : LinearGradient(
                        colors: [Colors.green.shade500, Colors.green.shade600],
                      ),
                color: message.isFromBot ? Colors.white : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isFromBot
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomRight: message.isFromBot
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message),
            ),
          ),
          if (!message.isFromBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromBot;
  final DateTime timestamp;
  final List<String> imageDataList;

  ChatMessage({
    required this.text,
    required this.isFromBot,
    required this.timestamp,
    this.imageDataList = const [],
  });
}

  /// Hiển thị text + ảnh (nếu quick chatbot trả về sản phẩm có imageData)
  Widget _buildMessageContent(ChatMessage message) {
    final textWidget = Text(
      message.text,
      style: TextStyle(
        color: message.isFromBot ? Colors.black87 : Colors.white,
        fontSize: 14,
        height: 1.4,
      ),
    );

    if (message.imageDataList.isEmpty) {
      return textWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        textWidget,
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: message.imageDataList.map((base64Str) {
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
                    base64Decode(base64Str),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            } catch (_) {
              return Container(
                width: 120,
                height: 120,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              );
            }
          }).toList(),
        ),
      ],
    );
  }

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
