import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ChatDetailPage extends StatefulWidget {
  final String maChat;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.maChat,
    required this.currentUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  final ChatApi _chatApi = ChatApi();
  final RagApi _ragApi = RagApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // TỐI ƯU: Sử dụng ValueNotifier thay vì setState toàn màn hình
  final ValueNotifier<List<Message>> _messagesNotifier = ValueNotifier<List<Message>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasMoreMessagesNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isUploadingFileNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isWaitingForBotResponseNotifier = ValueNotifier<bool>(false);
  
  // Getters để tương thích với code cũ
  List<Message> get _messages => _messagesNotifier.value;
  bool get _hasMoreMessages => _hasMoreMessagesNotifier.value;
  bool get _isLoadingMore => _isLoadingMoreNotifier.value;
  bool get _isSending => _isSendingNotifier.value;
  
  Timer? _refreshTimer;
  Timer? _botResponseWaitTimer;
  String? _selectedFileId;
  DateTime? _lastScrollCheck;
  bool _isPageVisible = true;
  
  // TỐI ƯU: Cache MediaQuery và DateFormat
  double? _cachedScreenWidth;
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    // Lắng nghe scroll để load more khi scroll lên đầu (với debounce)
    _scrollController.addListener(_onScroll);
    // TỐI ƯU: Tăng interval từ 5s lên 8s để giảm API calls và rebuild
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _isPageVisible) {
        _loadNewMessages();
      }
    });
  }

  void _onScroll() {
    // Debounce scroll listener - chỉ check mỗi 200ms để tối ưu hiệu năng
    final now = DateTime.now();
    if (_lastScrollCheck != null && 
        now.difference(_lastScrollCheck!).inMilliseconds < 200) {
      return;
    }
    _lastScrollCheck = now;

    // Kiểm tra nếu scroll controller có clients và position hợp lệ
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
      return;
    }

    // Khi scroll đến đầu danh sách (trong vòng 150px), load thêm tin nhắn cũ
    if (_scrollController.position.pixels <= 150 && 
        _hasMoreMessages && 
        !_isLoadingMore && 
        _messages.isNotEmpty) {
      _loadMoreMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _botResponseWaitTimer?.cancel();
    
    // TỐI ƯU: Dispose ValueNotifiers
    _messagesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isLoadingMoreNotifier.dispose();
    _hasMoreMessagesNotifier.dispose();
    _isSendingNotifier.dispose();
    _isUploadingFileNotifier.dispose();
    _isWaitingForBotResponseNotifier.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Tắt auto-refresh khi app ở background để tiết kiệm tài nguyên
    _isPageVisible = state == AppLifecycleState.resumed;
    if (!_isPageVisible) {
      // Hủy bot response timer khi app vào background
      _botResponseWaitTimer?.cancel();
    }
  }

  void _waitForBotResponse() {
    // Hủy timer cũ nếu có
    _botResponseWaitTimer?.cancel();
    
    // TỐI ƯU: Chỉ update flag, không rebuild toàn màn hình
    _isWaitingForBotResponseNotifier.value = true;
    
    // Scroll xuống cuối để hiển thị typing indicator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    int attempts = 0;
    const maxAttempts = 8; // Giảm từ 10 xuống 8 lần (8 giây)
    
    _botResponseWaitTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      attempts++;
      if (mounted && _isPageVisible) {
        _loadNewMessages();
        
        // Kiểm tra xem bot đã phản hồi chưa
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          if (lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT') {
            // Bot đã phản hồi, tắt indicator và scroll xuống
            _isWaitingForBotResponseNotifier.value = false;
            timer.cancel();
            
            // Scroll xuống để hiển thị tin nhắn mới từ bot
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && mounted) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            return;
          }
        }
      }
      
      // Dừng sau maxAttempts lần
      if (attempts >= maxAttempts) {
        _isWaitingForBotResponseNotifier.value = false;
        timer.cancel();
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      _isLoadingNotifier.value = true;
    }

    try {
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 10,
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        // TỐI ƯU: Chỉ update ValueNotifier, không rebuild toàn màn hình
        _messagesNotifier.value = newMessages;
        _hasMoreMessagesNotifier.value = hasMore;
        _isLoadingNotifier.value = false;

        // Mark as read
        await _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentUserId,
        );

        // Scroll to bottom
        if (_messages.isNotEmpty && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  /// Load thêm tin nhắn cũ hơn khi scroll lên
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _messages.isEmpty) return;

    _isLoadingMoreNotifier.value = true;

    try {
      // Lấy ID của tin nhắn cũ nhất hiện tại
      final oldestMessage = _messages.first;
      
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 10,
        beforeMessageId: oldestMessage.maTinNhan,
      );

      if (mounted) {
        final olderMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        if (olderMessages.isNotEmpty) {
          // Lưu vị trí scroll hiện tại
          final currentScrollPosition = _scrollController.position.pixels;
          final currentMaxScroll = _scrollController.position.maxScrollExtent;
          
          // TỐI ƯU: Update ValueNotifier thay vì setState
          final updatedMessages = [...olderMessages, ..._messages];
          _messagesNotifier.value = updatedMessages;
          _hasMoreMessagesNotifier.value = hasMore;
          _isLoadingMoreNotifier.value = false;

          // Khôi phục vị trí scroll sau khi thêm tin nhắn
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final newMaxScroll = _scrollController.position.maxScrollExtent;
              final scrollDifference = newMaxScroll - currentMaxScroll;
              _scrollController.jumpTo(currentScrollPosition + scrollDifference);
            }
          });
        } else {
          _hasMoreMessagesNotifier.value = false;
          _isLoadingMoreNotifier.value = false;
        }
      }
    } catch (e) {
      if (mounted) {
        _isLoadingMoreNotifier.value = false;
      }
    }
  }

  /// Load chỉ tin nhắn mới (dùng cho auto-refresh) - tối ưu để tránh rebuild không cần thiết
  Future<void> _loadNewMessages() async {
    if (!_isPageVisible) return; // Không load khi page không visible
    
    try {
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 10,
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
          // Chỉ cập nhật nếu có tin nhắn mới
        if (newMessages.length != _messages.length || 
            (newMessages.isNotEmpty && _messages.isNotEmpty && 
             newMessages.last.maTinNhan != _messages.last.maTinNhan)) {
          
          // Lưu số tin nhắn cũ để biết có tin nhắn mới không
          final oldLastMessageId = _messages.isNotEmpty ? _messages.last.maTinNhan : null;
          
          // Kiểm tra xem bot đã phản hồi chưa
          bool botResponded = false;
          if (newMessages.isNotEmpty) {
            final lastMessage = newMessages.last;
            if (lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT') {
              botResponded = true;
            }
          }
          
          // TỐI ƯU: Chỉ update ValueNotifier, không rebuild toàn màn hình
          _messagesNotifier.value = newMessages;
          _hasMoreMessagesNotifier.value = hasMore;
          if (botResponded) {
            _isWaitingForBotResponseNotifier.value = false;
          }

          // Scroll to bottom nếu có tin nhắn mới
          if (oldLastMessageId != null && 
              newMessages.isNotEmpty && 
              newMessages.last.maTinNhan != oldLastMessageId &&
              _scrollController.hasClients) {
            // Kiểm tra xem tin nhắn mới có phải từ bot không
            final lastMessage = newMessages.last;
            final isFromBot = lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT';
            
            // Nếu là tin nhắn từ bot, luôn scroll xuống
            // Nếu là tin nhắn từ user, chỉ scroll nếu đang ở gần cuối
            final isNearBottom = _scrollController.position.pixels >= 
                _scrollController.position.maxScrollExtent - 200;
            
            if (isFromBot || isNearBottom) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && mounted) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          }

          // Mark as read (chỉ khi có tin nhắn mới)
          if (oldLastMessageId != null && 
              newMessages.isNotEmpty && 
              newMessages.last.maTinNhan != oldLastMessageId) {
            await _chatApi.markAsRead(
              maChat: widget.maChat,
              maNguoiDoc: widget.currentUserId,
            );
          }
        }
      }
    } catch (e) {
      // Silent fail cho auto-refresh - không log để tránh spam
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _isSendingNotifier.value = true;

    try {
      // Nếu có file đã upload, hỏi đáp với RAG
      if (_selectedFileId != null) {
        final response = await _ragApi.askWithDocument(
          question: text,
          fileId: _selectedFileId,
          maChat: widget.maChat,
          baseUrl: Constant().baseUrl,
        );

        if (response != null && mounted) {
          // Gửi câu hỏi của user
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );

          // Bot sẽ tự động trả lời (đã xử lý ở backend)
          _messageController.clear();
          _loadNewMessages();
          // Bắt đầu chờ bot phản hồi (sẽ hiển thị typing indicator)
          _waitForBotResponse();
        } else {
          // Fallback: gửi tin nhắn thường
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );
          _messageController.clear();
          _loadNewMessages();
          // Bắt đầu chờ bot phản hồi (sẽ hiển thị typing indicator)
          _waitForBotResponse();
        }
      } else {
        // Gửi tin nhắn thường
        final success = await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: text,
        );

        if (success && mounted) {
          _messageController.clear();
          // Refresh ngay lập tức và tiếp tục refresh mỗi 1 giây trong 10 giây để đợi bot phản hồi
          _loadNewMessages();
          // Bắt đầu chờ bot phản hồi (sẽ hiển thị typing indicator)
          _waitForBotResponse();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        _isSendingNotifier.value = false;
      }
    }
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        _isUploadingFileNotifier.value = true;

        // Hiển thị loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Upload file lên RAG service
        final response = await _ragApi.uploadDocument(file);

        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
        }

        if (response != null && mounted) {
          _selectedFileId = response['file_id'];
          _isUploadingFileNotifier.value = false;

          // Gửi thông báo vào chat
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: '📄 Đã upload file: ${result.files.single.name}',
          );

          _loadNewMessages();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload thành công! Bạn có thể hỏi về file này.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _isUploadingFileNotifier.value = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upload thất bại. Vui lòng thử lại.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      _isUploadingFileNotifier.value = false;
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TỐI ƯU: Cache MediaQuery một lần
    if (_cachedScreenWidth == null) {
      _cachedScreenWidth = MediaQuery.of(context).size.width;
    }
    
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.supportChat,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Hỗ trợ trực tuyến',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          // Nút upload file
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.attach_file,
                color: Colors.grey.shade700,
                size: 22,
              ),
              onPressed: _isUploadingFileNotifier.value ? null : _uploadDocument,
              tooltip: 'Upload file để hỏi đáp',
            ),
          ),
          // Hiển thị nếu có file đã chọn
          if (_selectedFileId != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.description,
                  color: Colors.green.shade700,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _selectedFileId = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã bỏ chọn file')),
                  );
                },
                tooltip: 'Bỏ chọn file',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: Column(
          children: [
            // TỐI ƯU: Sử dụng ValueListenableBuilder thay vì setState toàn màn hình
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<Message>>(
                    valueListenable: _messagesNotifier,
                    builder: (context, messages, _) {
                      if (isLoading && messages.isEmpty) {
                        return _buildLoadingWidget();
                      }
                      if (messages.isEmpty) {
                        return _buildEmptyWidget(localizations);
                      }
                      return _buildMessagesList(theme);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(localizations, theme),
          ],
        ),
      ),
    );
  }


  // TỐI ƯU: Tách widget riêng để tránh rebuild không cần thiết
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải tin nhắn...',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.noMessages,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu cuộc trò chuyện với chúng tôi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // TỐI ƯU: Tách messages list với ValueListenableBuilder
  Widget _buildMessagesList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _loadMessages(),
      color: Colors.green.shade600,
      child: Column(
        children: [
          // TỐI ƯU: Chỉ rebuild loading indicator khi cần
          ValueListenableBuilder<bool>(
            valueListenable: _isLoadingMoreNotifier,
            builder: (context, isLoadingMore, _) {
              if (!isLoadingMore) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                child: const CircularProgressIndicator(),
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder<List<Message>>(
              valueListenable: _messagesNotifier,
              builder: (context, messages, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isWaitingForBotResponseNotifier,
                  builder: (context, isWaiting, _) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      reverse: false,
                      itemCount: messages.length + (isWaiting ? 1 : 0),
                      // TỐI ƯU: Tăng cacheExtent và thêm các flags
                      cacheExtent: 2000,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        if (isWaiting && index == messages.length) {
                          return _TypingIndicatorWidget(screenWidth: _cachedScreenWidth ?? 400);
                        }
                        final message = messages[index];
                        // TỐI ƯU: Sử dụng key ổn định và cache screenWidth
                        return MessageBubble(
                          key: ValueKey(message.maTinNhan),
                          message: message,
                          screenWidth: _cachedScreenWidth ?? 400,
                          timeFormat: _timeFormat,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Nút attach file
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isUploadingFileNotifier,
                builder: (context, isUploading, _) {
                  return isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: Colors.grey.shade700,
                            size: 22,
                          ),
                          onPressed: _uploadDocument,
                          tooltip: 'Upload file (PDF, DOCX, TXT, XLSX)',
                          padding: EdgeInsets.zero,
                        );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: localizations.typeMessage,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nút send
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade500,
                    Colors.green.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSendingNotifier.value ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(22),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isSendingNotifier,
                    builder: (context, isSending, _) {
                      return isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TỐI ƯU: Typing indicator widget riêng với const
class _TypingIndicatorWidget extends StatelessWidget {
  final double screenWidth;

  const _TypingIndicatorWidget({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A085), Color(0xFF138D75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
          ),
        ],
      ),
    );
  }

  // TỐI ƯU: Tách widget riêng để tránh rebuild không cần thiết
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A085)),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải tin nhắn...',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.noMessages,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu cuộc trò chuyện với chúng tôi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget bất biến để hiển thị message bubble - tối ưu hiệu năng
class MessageBubble extends StatelessWidget {
  final Message message;
  final double screenWidth;
  final DateFormat timeFormat;

  const MessageBubble({
    super.key,
    required this.message,
    required this.screenWidth,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    // TỐI ƯU: Sử dụng cached values thay vì tính toán lại
    final maxWidth = screenWidth * 0.75;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.support_agent,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isFromUser
                    ? LinearGradient(
                        colors: [Colors.green.shade500, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isFromUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isFromUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isFromUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFromUser ? Colors.green : Colors.black).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.noiDung,
                    style: TextStyle(
                      color: isFromUser ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormat.format(message.ngayGui),
                        style: TextStyle(
                          color: isFromUser
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isFromUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.daDoc ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.daDoc
                              ? Colors.blue.shade300
                              : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
}

/// Widget hiển thị 1 chấm đang nhảy (typing animation) - giống quick_chatbot_dialog
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

