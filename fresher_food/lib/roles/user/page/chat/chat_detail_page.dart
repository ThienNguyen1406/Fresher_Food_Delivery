import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/chat_app_bar.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/message_input.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/messages_list.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/loading_widget.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/empty_widget.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void unawaited(Future<void> future) {}

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
  final CategoryApi _categoryApi = CategoryApi();
  final ProductApi _productApi = ProductApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final ValueNotifier<List<Message>> _messagesNotifier = ValueNotifier<List<Message>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasMoreMessagesNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isUploadingFileNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isWaitingForBotResponseNotifier = ValueNotifier<bool>(false);
  
  List<Message> get _messages => _messagesNotifier.value;
  bool get _hasMoreMessages => _hasMoreMessagesNotifier.value;
  bool get _isLoadingMore => _isLoadingMoreNotifier.value;
  bool get _isSending => _isSendingNotifier.value;
  
  Timer? _refreshTimer;
  Timer? _botResponseWaitTimer;
  String? _selectedFileId;
  File? _selectedImage;
  DateTime? _lastScrollCheck;
  bool _isPageVisible = true;
  bool _isWaitingForBot = false;
  
  DateTime? _lastLoadMessagesTime;
  bool _isLoadingMessages = false;
  String? _lastMessageId;
  
  bool _isUserScrolling = false;
  DateTime? _lastUserScrollTime;
  
  double? _cachedScreenWidth;
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _scrollController.addListener(_onScroll);
    _startRefreshTimer();
  }

  void _onScroll() {
    final now = DateTime.now();
    if (_lastScrollCheck != null && 
        now.difference(_lastScrollCheck!).inMilliseconds < 300) {
      return;
    }
    _lastScrollCheck = now;

    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
      return;
    }

    final currentPosition = _scrollController.position.pixels;
    final maxPosition = _scrollController.position.maxScrollExtent;
    
    // Với reverse: true, pixels = 0 là bottom (mới nhất), maxPosition là top (cũ nhất)
    // Khi scroll lên để xem tin nhắn cũ, pixels tăng lên gần maxPosition
    if (currentPosition < maxPosition - 300) {
      _isUserScrolling = true;
      _lastUserScrollTime = now;
    } else {
      if (_lastUserScrollTime != null && 
          now.difference(_lastUserScrollTime!).inSeconds > 2) {
        _isUserScrolling = false;
      }
    }

    // Với reverse: true, load more khi gần top (maxPosition)
    // Kiểm tra nếu còn cách top ít hơn 200px
    final distanceFromTop = maxPosition - currentPosition;
    if (distanceFromTop <= 200 && 
        _hasMoreMessages && 
        !_isLoadingMore && 
        _messages.isNotEmpty) {
      _loadMoreMessages();
    }
  }

  /// Xóa cuộc trò chuyện
  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await _chatApi.deleteChat(widget.maChat, widget.currentUserId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa cuộc trò chuyện'),
              backgroundColor: Colors.green,
            ),
          );
          // Quay lại màn hình trước
          Navigator.of(context).pop(true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa cuộc trò chuyện'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Tạo chat mới
  void _createNewChat() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _botResponseWaitTimer?.cancel();
    
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
    _isPageVisible = state == AppLifecycleState.resumed;
    if (!_isPageVisible) {
      _botResponseWaitTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    
    if (_isWaitingForBot) {
      return;
    }
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _isPageVisible && !_isWaitingForBot) {
        _loadNewMessages();
      }
    });
  }
  
  void _waitForBotResponse() {
    _botResponseWaitTimer?.cancel();
    _refreshTimer?.cancel();
    
    _isWaitingForBot = true;
    _isWaitingForBotResponseNotifier.value = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted && !_isUserScrolling) {
        _scrollController.jumpTo(0);
      }
    });
    
    int attempts = 0;
    const maxAttempts = 20;
    
    _botResponseWaitTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      attempts++;
      if (mounted && _isPageVisible) {
        _loadNewMessages();
        
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.first;
          if (lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT') {
            _isWaitingForBot = false;
            _isWaitingForBotResponseNotifier.value = false;
            timer.cancel();
            _startRefreshTimer();
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && mounted) {
                _scrollController.jumpTo(0);
              }
            });
            return;
          }
        }
      }
      
      if (attempts >= maxAttempts) {
        _isWaitingForBot = false;
        _isWaitingForBotResponseNotifier.value = false;
        timer.cancel();
        _startRefreshTimer();
      }
    });
  }

  Future<void> _loadMessages({bool silent = false, bool forceReload = false}) async {
    if (!silent) {
      _isLoadingNotifier.value = true;
    }

    try {
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 5, // Giảm từ 10 xuống 5 để load nhanh hơn
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        final reversedMessages = newMessages.reversed.toList();
        
        if (reversedMessages.isNotEmpty) {
          _lastMessageId = reversedMessages.first.maTinNhan;
        }
        
        // Nếu forceReload = true (pull to refresh), thay thế toàn bộ
        // Nếu không, merge với messages hiện có để giữ lại tin nhắn cũ đã load
        if (forceReload) {
          _messagesNotifier.value = reversedMessages;
        } else {
          final currentMessages = _messages;
          if (currentMessages.isEmpty) {
            // Nếu chưa có messages, set trực tiếp
            _messagesNotifier.value = reversedMessages;
          } else {
            // Merge: chỉ thêm tin nhắn mới, giữ lại tin nhắn cũ
            final existingIds = <String>{};
            for (var msg in currentMessages) {
              existingIds.add(msg.maTinNhan);
            }
            
            final updatedMessages = <Message>[];
            for (var newMsg in reversedMessages) {
              if (!existingIds.contains(newMsg.maTinNhan)) {
                updatedMessages.add(newMsg);
              }
            }
            
            // Giữ lại tin nhắn cũ đã load trước đó
            if (updatedMessages.isNotEmpty) {
              _messagesNotifier.value = [...updatedMessages, ...currentMessages];
            }
          }
        }
        
        _hasMoreMessagesNotifier.value = hasMore;
        _isLoadingNotifier.value = false;

        // markAsRead không block UI
        unawaited(
          _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentUserId,
          ).catchError((e) {
            return false;
          })
        );
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
      // Với reverse: true, _messages.last là tin nhắn cũ nhất (ở top)
      final oldestMessage = _messages.last;
      
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 20,
        beforeMessageId: oldestMessage.maTinNhan,
      );

      if (mounted) {
        final olderMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        if (olderMessages.isNotEmpty) {
          final reversedOlderMessages = olderMessages.reversed.toList();
          
          final currentScrollPosition = _scrollController.position.pixels;
          final currentMaxScroll = _scrollController.position.maxScrollExtent;
          
          // Thêm tin nhắn cũ vào cuối list (sau tin nhắn cũ nhất hiện tại)
          final updatedMessages = [..._messages, ...reversedOlderMessages];
          _messagesNotifier.value = updatedMessages;
          _hasMoreMessagesNotifier.value = hasMore;
          _isLoadingMoreNotifier.value = false;

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
      print('Error loading more messages: $e');
    }
  }

  /// Sync optimistic message với real message từ server (không reload toàn bộ)
  Future<void> _syncOptimisticMessage(String tempMessageId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 3,
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final reversedNewMessages = newMessages.reversed.toList();
        
        final currentMessages = List<Message>.from(_messages);
        final tempIndex = currentMessages.indexWhere((m) => m.maTinNhan == tempMessageId);
        
        if (tempIndex != -1 && reversedNewMessages.isNotEmpty) {
          final realMessage = reversedNewMessages.firstWhere(
            (m) => m.maNguoiGui == widget.currentUserId && 
                   m.noiDung.trim() == currentMessages[tempIndex].noiDung.trim(),
            orElse: () => reversedNewMessages.first,
          );
          
          currentMessages[tempIndex] = realMessage;
          _messagesNotifier.value = currentMessages;
          
          if (reversedNewMessages.isNotEmpty) {
            _lastMessageId = reversedNewMessages.first.maTinNhan;
          }
        }
      }
    } catch (e) {
    }
  }

  /// Load chỉ tin nhắn mới (dùng cho auto-refresh)
  Future<void> _loadNewMessages() async {
    if (!_isPageVisible) return;
    
    final now = DateTime.now();
    if (_lastLoadMessagesTime != null && 
        now.difference(_lastLoadMessagesTime!).inMilliseconds < 1000) { // Giảm debounce từ 1500ms xuống 1000ms
      return;
    }
    
    if (_isLoadingMessages) return;
    
    _isLoadingMessages = true;
    _lastLoadMessagesTime = now;
    
    try {
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 2, // Giảm từ 3 xuống 2 để load nhanh hơn
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        final reversedNewMessages = newMessages.reversed.toList();
        final newLastMessageId = reversedNewMessages.isNotEmpty ? reversedNewMessages.first.maTinNhan : null;
        final hasNewMessages = newLastMessageId != null && newLastMessageId != _lastMessageId;
        
        if (hasNewMessages) {
          _lastMessageId = newLastMessageId;
          
          final currentMessages = List<Message>.from(_messages);
          final currentLastMessageId = currentMessages.isNotEmpty ? currentMessages.first.maTinNhan : null;
          
          bool botResponded = false;
          if (reversedNewMessages.isNotEmpty) {
            final lastMessage = reversedNewMessages.first;
            if (lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT') {
              botResponded = true;
            }
          }
          
          final updatedMessages = <Message>[];
          final existingIds = currentMessages.map((m) => m.maTinNhan).toSet();
          final messagesToRemove = <String>{};
          
          for (var newMsg in reversedNewMessages) {
            if (!existingIds.contains(newMsg.maTinNhan)) {
              updatedMessages.add(newMsg);
              
              if (newMsg.maNguoiGui == widget.currentUserId) {
                final newMsgContent = newMsg.noiDung.replaceAll(RegExp(r'\[IMAGE_DATA\].*?\[/IMAGE_DATA\]'), '').trim();
                
                for (var existingMsg in currentMessages) {
                  if (existingMsg.maTinNhan.startsWith('temp_') && 
                      existingMsg.maNguoiGui == widget.currentUserId) {
                    final existingContent = existingMsg.noiDung.replaceAll(RegExp(r'\[IMAGE_DATA\].*?\[/IMAGE_DATA\]'), '').trim();
                    
                    if (newMsgContent == existingContent || 
                        newMsgContent.contains(existingContent) || 
                        existingContent.contains(newMsgContent)) {
                      messagesToRemove.add(existingMsg.maTinNhan);
                      break;
                    }
                  }
                }
              }
            }
          }
          
          if (updatedMessages.isNotEmpty || messagesToRemove.isNotEmpty) {
            final filteredCurrentMessages = currentMessages.where((m) => !messagesToRemove.contains(m.maTinNhan)).toList();
            final mergedMessages = [...updatedMessages, ...filteredCurrentMessages];
            _messagesNotifier.value = mergedMessages;
          _hasMoreMessagesNotifier.value = hasMore;
            
          if (botResponded) {
            _isWaitingForBotResponseNotifier.value = false;
          }

            if (currentLastMessageId != null && 
                reversedNewMessages.isNotEmpty && 
                reversedNewMessages.first.maTinNhan != currentLastMessageId &&
              _scrollController.hasClients) {
              final lastMessage = reversedNewMessages.first;
            final isFromBot = lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT';
            
            final isNearTop = _scrollController.position.pixels <= 200;
            
            if ((isFromBot || isNearTop) && !_isUserScrolling) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && mounted) {
                  final currentPosition = _scrollController.position.pixels;
                  
                  final isStillNearTop = currentPosition <= 300;
                  
                  if ((isFromBot && currentPosition > 50) || 
                      (isNearTop && isStillNearTop && currentPosition > 50)) {
                    _scrollController.jumpTo(0);
                  }
                }
              });
            }
          }

            if (currentLastMessageId != null && 
                reversedNewMessages.isNotEmpty && 
                reversedNewMessages.first.maTinNhan != currentLastMessageId) {
              unawaited(
                _chatApi.markAsRead(
              maChat: widget.maChat,
              maNguoiDoc: widget.currentUserId,
                ).catchError((e) {
                  return false;
                })
            );
            }
          }
        }
      }
    } catch (e) {
    } finally {
      _isLoadingMessages = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    
    if (_selectedImage != null) {
      await _searchProductsByImage();
      return;
    }
    
    if (text.isEmpty || _isSending) return;

    _isSendingNotifier.value = true;

    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      maTinNhan: tempMessageId,
      maChat: widget.maChat,
      maNguoiGui: widget.currentUserId,
      loaiNguoiGui: 'User',
      noiDung: text,
      ngayGui: DateTime.now(),
      daDoc: false,
    );
    
    final currentMessages = List<Message>.from(_messages);
    currentMessages.insert(0, optimisticMessage);
    _messagesNotifier.value = currentMessages;
    
    _messageController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        if (!_isUserScrolling) {
          _scrollController.jumpTo(0);
        }
      }
    });

    try {
      if (_selectedFileId != null) {
        final response = await _ragApi.askWithDocument(
          question: text,
          fileId: _selectedFileId,
          maChat: widget.maChat,
          baseUrl: Constant().baseUrl,
        );

        if (response != null && mounted) {
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );

          _waitForBotResponse();
          unawaited(_syncOptimisticMessage(tempMessageId));
        } else {
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );
          _waitForBotResponse();
          unawaited(_syncOptimisticMessage(tempMessageId));
        }
      } else {
        _isWaitingForBotResponseNotifier.value = true;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted && !_isUserScrolling) {
            _scrollController.jumpTo(0);
          }
        });
        
        final success = await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: text,
        );

        if (success && mounted) {
          _waitForBotResponse();
          
          unawaited(_syncOptimisticMessage(tempMessageId));
        } else if (mounted) {
          _isWaitingForBotResponseNotifier.value = false;
          final updatedMessages = _messages.where((m) => m.maTinNhan != tempMessageId).toList();
          _messagesNotifier.value = updatedMessages;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final updatedMessages = _messages.where((m) => m.maTinNhan != tempMessageId).toList();
        _messagesNotifier.value = updatedMessages;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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

  Future<void> _pickImageForSearch() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _searchProductsByImage() async {
    if (_selectedImage == null) return;

    final imageFile = _selectedImage!;
    final description = _messageController.text.trim();
    
    _isUploadingFileNotifier.value = true;
    
    String messageContent = description.isNotEmpty 
        ? '🖼️ $description'
        : '🖼️ Cửa hàng của bạn có sản phẩm này không ??';
    
    final tempMessageId = 'temp_image_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticImageMessage = Message(
      maTinNhan: tempMessageId,
      maChat: widget.maChat,
      maNguoiGui: widget.currentUserId,
      loaiNguoiGui: 'User',
      noiDung: '$messageContent\n\n[IMAGE_DATA]${imageFile.path}[/IMAGE_DATA]',
      ngayGui: DateTime.now(),
      daDoc: false,
    );
    
    final currentMessages = List<Message>.from(_messages);
    currentMessages.insert(0, optimisticImageMessage);
    _messagesNotifier.value = currentMessages;
    
    setState(() {
      _selectedImage = null;
    });
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted && !_isUserScrolling) {
        _scrollController.jumpTo(0);
      }
    });

    String? imageBase64;
    try {
      final imageBytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
    }
    
    if (imageBase64 != null) {
      final updatedMessageContent = '$messageContent\n\n[IMAGE_DATA]$imageBase64[/IMAGE_DATA]';
      final updatedMessages = List<Message>.from(_messages);
      final messageIndex = updatedMessages.indexWhere((m) => m.maTinNhan == tempMessageId);
      if (messageIndex != -1) {
        updatedMessages[messageIndex] = Message(
          maTinNhan: tempMessageId,
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: updatedMessageContent,
          ngayGui: updatedMessages[messageIndex].ngayGui,
          daDoc: false,
        );
        _messagesNotifier.value = updatedMessages;
      }
    }

    try {
      final finalMessageContent = imageBase64 != null
          ? '$messageContent\n\n[IMAGE_DATA]$imageBase64[/IMAGE_DATA]'
          : messageContent;
      
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: widget.currentUserId,
        loaiNguoiGui: 'User',
        noiDung: finalMessageContent,
      );
      
      _isWaitingForBotResponseNotifier.value = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted && !_isUserScrolling) {
          _scrollController.jumpTo(0);
        }
      });

      final result = await _ragApi.searchProductsByImage(
        imageFile: imageFile,
        userDescription: description,
        topK: 10,
      );

      _isWaitingForBotResponseNotifier.value = false;
      _isUploadingFileNotifier.value = false;

      if (result != null && result['results'] != null && mounted) {
        final List<dynamic> products = result['results'];
        
        const double similarityThreshold = 0.65;
        
        if (products.isEmpty) {
          await _sendFallbackProducts();
        } else {
          final productsWithImages = await _fetchProductImages(products);
          
          productsWithImages.sort((a, b) {
            final simA = a['similarity'] as double? ?? 0.0;
            final simB = b['similarity'] as double? ?? 0.0;
            return simB.compareTo(simA);
          });
          
          final productsWithImage = productsWithImages.where((p) {
            final imageData = p['imageData'] as String?;
            return imageData != null && imageData.isNotEmpty;
          }).toList();
          
          final bestProduct = productsWithImages.isNotEmpty ? productsWithImages.first : null;
          final bestSimilarity = bestProduct?['similarity'] as double? ?? 0.0;
          
          List<Map<String, dynamic>> selectedProducts = [];
          String textMessage;
          
          if (bestSimilarity < similarityThreshold) {
            final categoryId = bestProduct?['categoryId'] as String?;
            if (categoryId != null && categoryId.isNotEmpty) {
              selectedProducts = await _getProductsByCategory(categoryId, limit: 3);
            }
            
            if (selectedProducts.isEmpty) {
              selectedProducts = await _getFallbackProducts(limit: 3);
            }
            
            textMessage = 'Bạn có thể tham khảo:\n';
            for (var i = 0; i < selectedProducts.length; i++) {
              final product = selectedProducts[i];
              final name = product['productName'] ?? 'N/A';
              final price = product['price'];
              textMessage += '${i + 1}. $name';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              }
              textMessage += '\n';
            }
          } else if (productsWithImage.isNotEmpty) {
            final bestProductWithImage = productsWithImage.first;
            final bestProductSimilarity = bestProductWithImage['similarity'] as double? ?? 0.0;
            
            if (bestProductSimilarity >= similarityThreshold) {
              selectedProducts = [bestProductWithImage];
              
              final productName = bestProductWithImage['productName'] as String?;
              final price = bestProductWithImage['price'];
              
              final displayName = (productName != null && productName.isNotEmpty && productName != 'N/A')
                  ? productName
                  : 'Sản phẩm';
              
              textMessage = 'Mình tìm thấy sản phẩm $displayName';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              } else {
                textMessage += ' (đang cập nhật giá)';
              }
            } else {
              selectedProducts = productsWithImage.take(3).toList();
              textMessage = 'Bạn có thể tham khảo:\n';
              for (var i = 0; i < selectedProducts.length; i++) {
                final product = selectedProducts[i];
                final name = product['productName'] ?? 'N/A';
                final price = product['price'];
                textMessage += '${i + 1}. $name';
                if (price != null) {
                  textMessage += ' - ${price.toStringAsFixed(0)}₫';
                }
                textMessage += '\n';
              }
            }
          } else {
            final productsWithImageForFallback = productsWithImages.where((p) {
              final imageData = p['imageData'] as String?;
              return imageData != null && imageData.isNotEmpty;
            }).take(3).toList();
            
            selectedProducts = productsWithImageForFallback.isNotEmpty 
                ? productsWithImageForFallback 
                : productsWithImages.take(3).toList();
            
            textMessage = 'Bạn có thể tham khảo:\n';
            for (var i = 0; i < selectedProducts.length; i++) {
              final product = selectedProducts[i];
              final name = product['productName'] ?? 'N/A';
              final price = product['price'];
              textMessage += '${i + 1}. $name';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              }
              textMessage += '\n';
            }
          }

          if (selectedProducts.isEmpty) {
            selectedProducts = await _getFallbackProducts(limit: 3);
            if (selectedProducts.isNotEmpty) {
              textMessage = 'Chúng tôi không có sản phẩm này, nhưng bạn có thể tham khảo:\n';
              for (var i = 0; i < selectedProducts.length; i++) {
                final product = selectedProducts[i];
                final name = product['productName'] ?? 'N/A';
                final price = product['price'];
                textMessage += '${i + 1}. $name';
                if (price != null) {
                  textMessage += ' - ${price.toStringAsFixed(0)}₫';
                }
                textMessage += '\n';
              }
            } else {
              textMessage = 'Xin lỗi, chúng tôi không tìm thấy sản phẩm tương tự.';
            }
          }

          final productsJson = jsonEncode({
            'products': selectedProducts,
            'hasImages': selectedProducts.any((p) => p['imageData'] != null && (p['imageData'] as String).isNotEmpty),
          });

          final messageContent = selectedProducts.isNotEmpty
              ? '$textMessage\n\n[PRODUCTS_DATA]$productsJson[/PRODUCTS_DATA]'
              : textMessage;

          final tempBotMessageId = 'bot_temp_${DateTime.now().millisecondsSinceEpoch}';
          final optimisticBotMessage = Message(
            maTinNhan: tempBotMessageId,
            maChat: widget.maChat,
            maNguoiGui: 'BOT',
            loaiNguoiGui: 'Admin',
            noiDung: messageContent,
            ngayGui: DateTime.now(),
            daDoc: false,
          );
          
          final currentMessages = List<Message>.from(_messages);
          currentMessages.insert(0, optimisticBotMessage);
          _messagesNotifier.value = currentMessages;
          
          _isWaitingForBotResponseNotifier.value = false;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && mounted && !_isUserScrolling) {
              _scrollController.jumpTo(0);
            }
          });

          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: 'BOT',
            loaiNguoiGui: 'Admin',
            noiDung: messageContent,
          );
          
          await _loadNewMessages();
          
          final updatedMessages = List<Message>.from(_messages);
          final hasRealMessage = updatedMessages.any((m) => 
            m.maNguoiGui == 'BOT' && 
            m.maTinNhan != tempBotMessageId &&
            m.noiDung.contains(textMessage.split('\n')[0])
          );
          
          if (hasRealMessage) {
            updatedMessages.removeWhere((m) => m.maTinNhan == tempBotMessageId);
            _messagesNotifier.value = updatedMessages;
          }
        }
      } else {
        _isWaitingForBotResponseNotifier.value = false;
        
        try {
          await _sendFallbackProducts();
    } catch (e) {
          try {
            final errorMessage = Message(
              maTinNhan: 'bot_error_${DateTime.now().millisecondsSinceEpoch}',
              maChat: widget.maChat,
              maNguoiGui: 'BOT',
              loaiNguoiGui: 'Admin',
              noiDung: 'Xin lỗi, chúng tôi không thể tìm kiếm sản phẩm lúc này. Vui lòng thử lại sau.',
              ngayGui: DateTime.now(),
              daDoc: false,
            );
            
            final currentMessages = List<Message>.from(_messages);
            currentMessages.insert(0, errorMessage);
            _messagesNotifier.value = currentMessages;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && mounted && !_isUserScrolling) {
                _scrollController.jumpTo(0);
              }
            });
            
            await _chatApi.sendMessage(
              maChat: widget.maChat,
              maNguoiGui: 'BOT',
              loaiNguoiGui: 'Admin',
              noiDung: errorMessage.noiDung,
            );
          } catch (e2) {
            print('Error sending error message: $e2');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tìm kiếm sản phẩm. Đã gửi sản phẩm gợi ý.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _isUploadingFileNotifier.value = false;
      _isWaitingForBotResponseNotifier.value = false;
      
      try {
        final errorMessage = Message(
          maTinNhan: 'bot_error_${DateTime.now().millisecondsSinceEpoch}',
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: 'Xin lỗi, có lỗi xảy ra khi tìm kiếm sản phẩm. Vui lòng thử lại sau.',
          ngayGui: DateTime.now(),
          daDoc: false,
        );
        
        final currentMessages = List<Message>.from(_messages);
        currentMessages.insert(0, errorMessage);
        _messagesNotifier.value = currentMessages;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted && !_isUserScrolling) {
            _scrollController.jumpTo(0);
          }
        });
        
        await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: errorMessage.noiDung,
        );
      } catch (e2) {
        print('Error sending error message: $e2');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      _isUploadingFileNotifier.value = false;
      _isWaitingForBotResponseNotifier.value = false;
    }
  }

  Map<String, String>? _cachedHeaders;
  
  /// Fetch product images từ backend
  Future<List<Map<String, dynamic>>> _fetchProductImages(List<dynamic> products) async {
    final baseUrl = Constant().baseUrl;
    
    // 🔥 TỐI ƯU: Cache headers
    if (_cachedHeaders == null) {
      _cachedHeaders = await ApiService().getHeaders();
    }
    final headers = _cachedHeaders!;
    
    try {
      // 🔥 TỐI ƯU: Fetch tất cả product info parallel thay vì tuần tự
      final productInfoFutures = products.map((product) async {
        final productId = product['product_id'] ?? '';
        final productName = product['product_name'] ?? 'N/A';
        final categoryId = product['category_id'] ?? '';
        final categoryName = product['category_name'] ?? '';
        final price = product['price'];
        final similarity = product['similarity'] ?? 0.0;
        
        String? imageData;
        String? imageMimeType;
        String? finalProductName = productName;
        
        if (productId.isNotEmpty) {
          try {
            // Gọi API để lấy thông tin product
            final productResponse = await http.get(
              Uri.parse('$baseUrl/Product/$productId'),
              headers: headers,
            ).timeout(const Duration(seconds: 5));
            
            if (productResponse.statusCode == 200) {
              final productData = jsonDecode(productResponse.body);
              final productInfo = productData is List && productData.isNotEmpty
                  ? productData[0]
                  : productData;
              
              // Lấy product name từ backend
              final backendProductName = productInfo['tenSanPham'] as String?;
              if (backendProductName != null && backendProductName.isNotEmpty) {
                finalProductName = backendProductName;
              }
              
              // Lấy image URL
              final imageUrl = productInfo['anh'] as String?;
              
              if (imageUrl != null && imageUrl.isNotEmpty) {
                // 🔥 TỐI ƯU: Download image parallel
                try {
                  final imageResponse = await http.get(Uri.parse(imageUrl)).timeout(
                    const Duration(seconds: 5),
                  );
                  
                  if (imageResponse.statusCode == 200) {
                    imageData = base64Encode(imageResponse.bodyBytes);
                    imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
                  }
                } catch (e) {
                  print('Error downloading image from $imageUrl: $e');
                }
              }
            }
          } catch (e) {
            print('Error fetching product $productId: $e');
          }
        }
        
        // Đảm bảo product name không rỗng
        if (finalProductName == null || finalProductName.isEmpty || finalProductName == 'N/A') {
          finalProductName = 'Sản phẩm #$productId';
        }
        
        return {
          'productId': productId,
          'productName': finalProductName,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'price': price,
          'similarity': similarity,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        };
      }).toList();
      
      final productsWithImages = await Future.wait(productInfoFutures);
      return productsWithImages;
    } catch (e) {
      print('Error fetching product images: $e');
      return [];
    }
  }

  /// Lấy sản phẩm theo category từ backend
  Future<List<Map<String, dynamic>>> _getProductsByCategory(String categoryId, {int limit = 3}) async {
    try {
      final products = await _categoryApi.getProductsByCategory(categoryId);
      
      if (products.isEmpty) {
        return [];
      }
      
      final limitedProducts = products.take(limit).toList();
      
      final productFutures = limitedProducts.map((product) async {
        String? imageData;
        String? imageMimeType;
        
        final imageUrl = product.anh;
        if (imageUrl.isNotEmpty) {
          try {
            final imageResponse = await http.get(Uri.parse(imageUrl)).timeout(
              const Duration(seconds: 5),
            );
            
            if (imageResponse.statusCode == 200) {
              imageData = base64Encode(imageResponse.bodyBytes);
              imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
            }
          } catch (e) {
            print('Error downloading image from $imageUrl: $e');
          }
        }
        
        return {
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        };
      }).toList();
      
      return await Future.wait(productFutures);
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  /// Lấy sản phẩm fallback (phổ biến) khi không tìm thấy
  Future<List<Map<String, dynamic>>> _getFallbackProducts({int limit = 3}) async {
    try {
      final products = await _productApi.getProducts();
      
      if (products.isEmpty) {
        return [];
      }
      
      products.sort((a, b) => b.soLuongTon.compareTo(a.soLuongTon));
      
      final limitedProducts = products.take(limit).toList();
      
      final productFutures = limitedProducts.map((product) async {
        String? imageData;
        String? imageMimeType;
        
        final imageUrl = product.anh;
        if (imageUrl.isNotEmpty) {
          try {
            final imageResponse = await http.get(Uri.parse(imageUrl)).timeout(
              const Duration(seconds: 5),
            );
            
            if (imageResponse.statusCode == 200) {
              imageData = base64Encode(imageResponse.bodyBytes);
              imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
            }
                    } catch (e) {
            print('Error downloading image from $imageUrl: $e');
          }
        }
        
        return {
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        };
      }).toList();
      
      return await Future.wait(productFutures);
      } catch (e) {
      print('Error getting fallback products: $e');
      return [];
    }
  }

  /// Gửi sản phẩm fallback khi không tìm thấy kết quả
  Future<void> _sendFallbackProducts() async {
    try {
      final fallbackProducts = await _getFallbackProducts(limit: 3);
      
      if (fallbackProducts.isEmpty) {
        await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: 'Xin lỗi, chúng tôi không tìm thấy sản phẩm tương tự.',
        );
        return;
      }
      
      String textMessage = 'Chúng tôi không có sản phẩm này, nhưng bạn có thể tham khảo:\n';
      for (var i = 0; i < fallbackProducts.length; i++) {
        final product = fallbackProducts[i];
        final name = product['productName'] ?? 'N/A';
        final price = product['price'];
        textMessage += '${i + 1}. $name';
        if (price != null) {
          textMessage += ' - ${price.toStringAsFixed(0)}₫';
        }
        textMessage += '\n';
      }
      
      // Tạo JSON data cho products với images
      final productsJson = jsonEncode({
        'products': fallbackProducts,
        'hasImages': fallbackProducts.any((p) => p['imageData'] != null && (p['imageData'] as String).isNotEmpty),
      });
      
      // Tạo message content với [PRODUCTS_DATA] tag
      final messageContent = '$textMessage\n\n[PRODUCTS_DATA]$productsJson[/PRODUCTS_DATA]';
      
      // 🔥 OPTIMISTIC UPDATE: Hiển thị kết quả ngay lập tức trên UI
      final tempBotMessageId = 'bot_temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticBotMessage = Message(
        maTinNhan: tempBotMessageId,
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: messageContent,
        ngayGui: DateTime.now(),
        daDoc: false,
      );
      
      final currentMessages = List<Message>.from(_messages);
      currentMessages.insert(0, optimisticBotMessage);
      _messagesNotifier.value = currentMessages;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted && !_isUserScrolling) {
          _scrollController.jumpTo(0);
        }
      });
      
      // Gửi tin nhắn từ bot (background)
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: messageContent,
      );
      
      // Load messages mới để thay thế optimistic message
      await _loadNewMessages();
      
      // Xóa optimistic message nếu đã có message thật từ server
      final updatedMessages = List<Message>.from(_messages);
      final hasRealMessage = updatedMessages.any((m) => 
        m.maNguoiGui == 'BOT' && 
        m.maTinNhan != tempBotMessageId &&
        m.noiDung.contains(textMessage.split('\n')[0])
      );
      
      if (hasRealMessage) {
        updatedMessages.removeWhere((m) => m.maTinNhan == tempBotMessageId);
        _messagesNotifier.value = updatedMessages;
      }
      
      // 🔥 Đảm bảo typing indicator đã tắt sau khi gửi fallback products
      _isWaitingForBotResponseNotifier.value = false;
    } catch (e) {
      print('Error sending fallback products: $e');
      // 🔥 Đảm bảo typing indicator đã tắt khi có lỗi
      _isWaitingForBotResponseNotifier.value = false;
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: 'Xin lỗi, có lỗi xảy ra khi tìm kiếm sản phẩm.',
      );
    } finally {
      _isWaitingForBotResponseNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedScreenWidth == null) {
      _cachedScreenWidth = MediaQuery.of(context).size.width;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: ChatAppBar(
        onDeleteChat: _deleteChat,
        onCreateNewChat: _createNewChat,
        onUploadDocument: _uploadDocument,
        isUploadingFileNotifier: _isUploadingFileNotifier,
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
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<Message>>(
                    valueListenable: _messagesNotifier,
                    builder: (context, messages, _) {
                      if (isLoading && messages.isEmpty) {
                        return const LoadingWidget();
                      }
                      if (messages.isEmpty) {
                        return const EmptyWidget();
                      }
                      return MessagesList(
                        scrollController: _scrollController,
                        messagesNotifier: _messagesNotifier,
                        isLoadingMoreNotifier: _isLoadingMoreNotifier,
                        isWaitingForBotResponseNotifier: _isWaitingForBotResponseNotifier,
                        screenWidth: _cachedScreenWidth ?? 400,
                        timeFormat: _timeFormat,
                        onRefresh: () => _loadMessages(forceReload: true),
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(
              messageController: _messageController,
              selectedImage: _selectedImage,
              isSendingNotifier: _isSendingNotifier,
              isUploadingFileNotifier: _isUploadingFileNotifier,
              onSendMessage: _sendMessage,
              onPickImage: _pickImageForSearch,
              onRemoveImage: _removeSelectedImage,
            ),
          ],
        ),
      ),
    );
  }
}

