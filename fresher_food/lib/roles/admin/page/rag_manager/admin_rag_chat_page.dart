import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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
  final RagApi _ragApi = RagApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Chat? _chatInfo;
  Timer? _refreshTimer;
  bool _isWaitingForBotResponse = false;
  bool _useMultiAgentRAG = true; // ✅ Mặc định sử dụng Multi-Agent RAG

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
      // ✅ Nếu sử dụng Multi-Agent RAG, gọi trực tiếp và hiển thị kết quả
      if (_useMultiAgentRAG) {
        try {
          // Gửi tin nhắn user trước
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );

          _messageController.clear();
          
          // Reload messages để hiển thị tin nhắn user
          await _loadMessages();
          
          // Gọi Multi-Agent RAG
          final multiAgentResponse = await _ragApi.multiAgentQuery(
            query: text,
            topK: 5,
            enableCritic: true,
            baseUrl: Constant().baseUrl,
          );
          
          if (multiAgentResponse != null && mounted) {
            final answer = multiAgentResponse['finalAnswer'] as String?;
            final confidence = multiAgentResponse['answerConfidence'] as double? ?? 0.0;
            final hasHallucination = multiAgentResponse['hasHallucination'] as bool? ?? false;
            
            if (answer != null && answer.isNotEmpty) {
              // Gửi tin nhắn bot với kết quả từ Multi-Agent RAG
              // Tạo tin nhắn bot giả để hiển thị ngay (backend sẽ tạo thật sau)
              // Hoặc có thể gọi API để tạo tin nhắn bot
              
              // Backend đã tự động tạo tin nhắn bot, chỉ cần reload
              // Nhưng để đảm bảo, có thể gửi tin nhắn bot thủ công nếu cần
              
              print('✅ Multi-Agent RAG response: Answer length=${answer.length}, Confidence=$confidence, HasHallucination=$hasHallucination');
            }
          }
        } catch (multiAgentError) {
          print('⚠️ Multi-Agent RAG error: $multiAgentError, falling back to standard chat');
          // Fallback: Gửi tin nhắn bình thường, backend sẽ xử lý
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );
          _messageController.clear();
          await _loadMessages();
        }
      } else {
        // Gửi tin nhắn user (Backend sẽ tự động xử lý RAG và trả lời)
        await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: text,
        );

        _messageController.clear();
        await _loadMessages();
      }
      
      // Đợi bot trả lời (backend sẽ tự động trả lời sau 2 giây)
      // Auto-refresh timer sẽ tự động check và load tin nhắn bot mới
      int waitCount = 0;
      while (_isWaitingForBotResponse && waitCount < 10 && mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        waitCount++;
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

  /// Decode base64 trong isolate để không block UI thread
  static Uint8List? _decodeBase64InIsolate(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  /// Parse message và hiển thị với products images nếu có
  Widget _buildMessageContent(String messageText, bool isUser) {
    // Tìm [PRODUCTS_DATA] tag (có thể có hoặc không có tag đóng)
    final productsDataStartRegex = RegExp(r'\[PRODUCTS_DATA\]', dotAll: true);
    final productsDataEndRegex = RegExp(r'\[/PRODUCTS_DATA\]', dotAll: true);
    
    final startMatch = productsDataStartRegex.firstMatch(messageText);
    final endMatch = productsDataEndRegex.firstMatch(messageText);
    
    // Lấy text message (loại bỏ [PRODUCTS_DATA] tag)
    String textMessage = messageText;
    String? jsonStr;
    
    if (startMatch != null) {
      final startIndex = startMatch.end;
      final endIndex = endMatch != null ? endMatch.start : messageText.length;
      
      // Lấy text trước [PRODUCTS_DATA]
      textMessage = messageText.substring(0, startMatch.start).trim();
      
      // Lấy JSON string
      jsonStr = messageText.substring(startIndex, endIndex).trim();
    }
    
    // Parse products data để lấy hình ảnh
    List<dynamic> productsWithImages = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final productsData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final products = productsData['products'] as List<dynamic>? ?? [];
        
        productsWithImages = products.where((p) {
          final imageData = p['imageData'] as String?;
          return imageData != null && imageData.isNotEmpty;
        }).toList();
        
        print('✅ Parsed ${productsWithImages.length} products with images');
      } catch (e) {
        print('❌ Error parsing products data: $e');
        print('❌ JSON string: ${jsonStr.substring(0, jsonStr.length > 200 ? 200 : jsonStr.length)}...');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (textMessage.isNotEmpty)
          Text(
            textMessage,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        if (productsWithImages.isNotEmpty) ...[
          if (textMessage.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: productsWithImages.map((product) {
              final imageData = product['imageData'] as String?;
              
              if (imageData != null && imageData.isNotEmpty) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<Uint8List?>(
                      future: compute(_decodeBase64InIsolate, imageData),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey),
                              );
                            },
                          );
                        }
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
        ],
      ],
    );
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
          // Toggle Multi-Agent RAG
          PopupMenuButton<String>(
            icon: Icon(
              _useMultiAgentRAG ? Iconsax.cpu : Iconsax.message_text,
              color: Colors.white,
            ),
            tooltip: 'Chế độ RAG',
            onSelected: (value) {
              setState(() {
                _useMultiAgentRAG = value == 'multi_agent';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _useMultiAgentRAG 
                      ? 'Đã bật Multi-Agent RAG (nâng cao)' 
                      : 'Đã tắt Multi-Agent RAG (RAG truyền thống)',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'multi_agent',
                child: Row(
                  children: [
                    Icon(
                      _useMultiAgentRAG ? Icons.check : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Multi-Agent RAG'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Nâng cao',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'traditional',
                child: Row(
                  children: [
                    Icon(
                      !_useMultiAgentRAG ? Icons.check : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('RAG Truyền thống'),
                  ],
                ),
              ),
            ],
          ),
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
                                        _buildMessageContent(
                                          message.noiDung,
                                          isUser,
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

