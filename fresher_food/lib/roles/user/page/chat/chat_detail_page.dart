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
  File? _selectedImage; // Ảnh đã chọn để tìm kiếm
  DateTime? _lastScrollCheck;
  bool _isPageVisible = true;
  bool _isWaitingForBot = false;
  
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
    // Tạo refresh timer động - sẽ thay đổi interval dựa trên trạng thái
    _startRefreshTimer();
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
    Navigator.of(context).pop(); // Quay lại chat list
    // Chat list page sẽ tự động tạo chat mới khi user gửi tin nhắn
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

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // Nếu đang chờ bot phản hồi, refresh nhanh hơn (2 giây)
    // Nếu không, refresh chậm hơn (8 giây) để tiết kiệm tài nguyên
    final interval = _isWaitingForBot 
        ? const Duration(seconds: 2) 
        : const Duration(seconds: 8);
    
    _refreshTimer = Timer.periodic(interval, (_) {
      if (mounted && _isPageVisible) {
        _loadNewMessages();
      }
    });
  }
  
  void _waitForBotResponse() {
    // Hủy timer cũ nếu có
    _botResponseWaitTimer?.cancel();
    
    // Đánh dấu đang chờ bot và tăng tốc refresh
    _isWaitingForBot = true;
    _isWaitingForBotResponseNotifier.value = true;
    _startRefreshTimer(); // Restart với interval ngắn hơn
    
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
    const maxAttempts = 12; // Tăng lên 12 lần (24 giây với interval 2s)
    
    _botResponseWaitTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      attempts++;
      if (mounted && _isPageVisible) {
        _loadNewMessages();
        
        // Kiểm tra xem bot đã phản hồi chưa
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          if (lastMessage.loaiNguoiGui == 'Admin' || lastMessage.maNguoiGui == 'BOT') {
            // Bot đã phản hồi, tắt indicator và scroll xuống
            _isWaitingForBot = false;
            _isWaitingForBotResponseNotifier.value = false;
            timer.cancel();
            _startRefreshTimer(); // Quay lại interval dài hơn
            
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
        _isWaitingForBot = false;
        _isWaitingForBotResponseNotifier.value = false;
        timer.cancel();
        _startRefreshTimer(); // Quay lại interval dài hơn
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      _isLoadingNotifier.value = true;
    }

    try {
      // TỐI ƯU: Load ít hơn ban đầu để nhanh hơn (chỉ 5 messages đầu)
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 5, // Giảm từ 10 xuống 5 để load nhanh hơn
      );
      
      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;
        
        // TỐI ƯU: Chỉ update ValueNotifier, không rebuild toàn màn hình
        _messagesNotifier.value = newMessages;
        _hasMoreMessagesNotifier.value = hasMore;
        _isLoadingNotifier.value = false;

        // Mark as read (async, không block UI)
        _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentUserId,
        ).catchError((e) {
          // Silent fail
          return false;
        });

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
    
    // Nếu có ảnh đã chọn, gửi tìm kiếm bằng ảnh
    if (_selectedImage != null) {
      await _searchProductsByImage();
      return;
    }
    
    if (text.isEmpty || _isSending) return;

    _isSendingNotifier.value = true;

    // OPTIMISTIC UPDATE: Thêm message vào UI ngay lập tức
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
    
    // Thêm message vào UI ngay lập tức
    final currentMessages = List<Message>.from(_messages);
    currentMessages.add(optimisticMessage);
    _messagesNotifier.value = currentMessages;
    
    // Clear input ngay lập tức
    _messageController.clear();
    
    // Scroll to bottom ngay lập tức
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

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
          // Gửi câu hỏi của user (đã hiển thị optimistic message rồi)
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );

          // Load lại messages từ server để có message ID thật
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
          // Load lại messages từ server
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
          // Load lại messages từ server để có message ID thật và sync
          _loadNewMessages();
          // Bắt đầu chờ bot phản hồi (sẽ hiển thị typing indicator)
          _waitForBotResponse();
        } else if (mounted) {
          // Nếu gửi thất bại, xóa optimistic message
          final updatedMessages = _messages.where((m) => m.maTinNhan != tempMessageId).toList();
          _messagesNotifier.value = updatedMessages;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Nếu có lỗi, xóa optimistic message
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
    
    // Convert image to base64 để lưu trong message
    String? imageBase64;
    try {
      final imageBytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
    }
    
    setState(() {
      _selectedImage = null; // Xóa ảnh sau khi bắt đầu search
    });
    _messageController.clear();

    try {
      // Gửi thông báo vào chat
      // QUAN TRỌNG: Base64 image data quá dài (27538 tokens) sẽ gây lỗi khi backend gửi đến RAG service
      // Backend CẦN loại bỏ [IMAGE_DATA]...[/IMAGE_DATA] tag trước khi gửi message đến RAG
      // để tránh lỗi "maximum context length is 8192 tokens"
      String messageContent = description.isNotEmpty 
          ? '🖼️ $description'
          : '🖼️ Shop bạn có sản phẩm này không';
      
      // Thêm image data vào message để lưu và hiển thị
      // Backend phải loại bỏ tag này trước khi gửi đến RAG
      if (imageBase64 != null) {
        messageContent += '\n\n[IMAGE_DATA]$imageBase64[/IMAGE_DATA]';
      }
      
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: widget.currentUserId,
        loaiNguoiGui: 'User',
        noiDung: messageContent,
      );
      
      // LƯU Ý: Backend cần được cập nhật để:
      // 1. Loại bỏ [IMAGE_DATA]...[/IMAGE_DATA] tag từ message trước khi gửi đến RAG
      // 2. Chỉ gửi text description đến RAG service để tạo embedding
      // 3. Image data chỉ để lưu trong database và hiển thị trên frontend

      // Tìm kiếm sản phẩm bằng ảnh
      final result = await _ragApi.searchProductsByImage(
        imageFile: imageFile,
        userDescription: description,
        topK: 10,
      );

      _isUploadingFileNotifier.value = false;

      if (result != null && result['results'] != null && mounted) {
        final List<dynamic> products = result['results'];
        
        // Ngưỡng similarity tối thiểu để coi là "tìm thấy" (50%)
        const double similarityThreshold = 0.5;
        
        if (products.isEmpty) {
          // Không có kết quả từ vector search - trả về sản phẩm phổ biến
          await _sendFallbackProducts();
        } else {
          // Fetch product images từ backend
          final productsWithImages = await _fetchProductImages(products);
          
          // Tìm sản phẩm có similarity cao nhất và có image
          final productsWithImage = productsWithImages.where((p) {
            final imageData = p['imageData'] as String?;
            return imageData != null && imageData.isNotEmpty;
          }).toList();
          
          // Sắp xếp theo similarity (cao nhất trước)
          productsWithImage.sort((a, b) {
            final simA = a['similarity'] as double? ?? 0.0;
            final simB = b['similarity'] as double? ?? 0.0;
            return simB.compareTo(simA);
          });
          
          // Sắp xếp tất cả products theo similarity
          productsWithImages.sort((a, b) {
            final simA = a['similarity'] as double? ?? 0.0;
            final simB = b['similarity'] as double? ?? 0.0;
            return simB.compareTo(simA);
          });
          
          // Lấy sản phẩm có similarity cao nhất
          final bestProduct = productsWithImages.isNotEmpty ? productsWithImages.first : null;
          final bestSimilarity = bestProduct?['similarity'] as double? ?? 0.0;
          
          List<Map<String, dynamic>> selectedProducts = [];
          String textMessage;
          
          // Kiểm tra nếu similarity quá thấp (< 50%) - coi như không tìm thấy
          if (bestSimilarity < similarityThreshold) {
            // Similarity thấp - trả về sản phẩm cùng category hoặc sản phẩm phổ biến
            final categoryId = bestProduct?['categoryId'] as String?;
            if (categoryId != null && categoryId.isNotEmpty) {
              // Lấy sản phẩm cùng category
              selectedProducts = await _getProductsByCategory(categoryId, limit: 3);
            }
            
            if (selectedProducts.isEmpty) {
              // Nếu không có category hoặc không lấy được, trả về sản phẩm phổ biến
              selectedProducts = await _getFallbackProducts(limit: 3);
            }
            
            // Tạo message cho sản phẩm gợi ý
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
          } else if (productsWithImage.isNotEmpty) {
            // Trường hợp 1: Có sản phẩm có hình ảnh và similarity >= 50%
            final bestProduct = productsWithImage.first;
            selectedProducts = [bestProduct];
            
            final productName = bestProduct['productName'] ?? 'N/A';
            final price = bestProduct['price'];
            
            // Tạo message: "Mình tìm thấy sản phẩm <tên> - <giá>₫"
            textMessage = 'Mình tìm thấy sản phẩm $productName';
            if (price != null) {
              textMessage += ' - ${price.toStringAsFixed(0)}₫';
            }
          } else {
            // Trường hợp 2: Không có sản phẩm nào có hình ảnh nhưng similarity >= 50%
            // Lấy tối đa 3 sản phẩm có hình ảnh để tham khảo
            // Ưu tiên sản phẩm có hình ảnh từ productsWithImages
            final productsWithImageForFallback = productsWithImages.where((p) {
              final imageData = p['imageData'] as String?;
              return imageData != null && imageData.isNotEmpty;
            }).take(3).toList();
            
            // Nếu không có sản phẩm có hình ảnh, lấy 3 sản phẩm đầu tiên
            selectedProducts = productsWithImageForFallback.isNotEmpty 
                ? productsWithImageForFallback 
                : productsWithImages.take(3).toList();
            
            // Tạo message với danh sách sản phẩm để tham khảo
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

          // Tạo JSON data cho products với images
          final productsJson = jsonEncode({
            'products': selectedProducts,
            'hasImages': selectedProducts.any((p) => p['imageData'] != null && (p['imageData'] as String).isNotEmpty),
          });

          // Tạo message content với [PRODUCTS_DATA] tag
          final messageContent = '$textMessage\n\n[PRODUCTS_DATA]$productsJson[/PRODUCTS_DATA]';

          // Gửi tin nhắn từ bot với kết quả
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: 'BOT',
            loaiNguoiGui: 'Admin',
            noiDung: messageContent,
          );
        }

        // KHÔNG gọi _waitForBotResponse() vì đã có kết quả tìm kiếm rồi
        // Chỉ load messages mới để hiển thị kết quả
        _loadNewMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tìm kiếm sản phẩm. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _isUploadingFileNotifier.value = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  /// Fetch product images từ backend
  Future<List<Map<String, dynamic>>> _fetchProductImages(List<dynamic> products) async {
    final List<Map<String, dynamic>> productsWithImages = [];
    final baseUrl = Constant().baseUrl;
    
    try {
      for (var product in products) {
        final productId = product['product_id'] ?? '';
        final productName = product['product_name'] ?? 'N/A';
        final categoryId = product['category_id'] ?? '';
        final categoryName = product['category_name'] ?? '';
        final price = product['price'];
        final similarity = product['similarity'] ?? 0.0;
        
        String? imageData;
        String? imageMimeType;
        
        // Lấy ảnh từ backend API
        if (productId.isNotEmpty) {
          try {
            // Gọi API để lấy thông tin product (bao gồm image URL)
            final productResponse = await http.get(
              Uri.parse('$baseUrl/Product/$productId'),
              headers: await ApiService().getHeaders(),
            ).timeout(const Duration(seconds: 5));
            
            if (productResponse.statusCode == 200) {
              final productData = jsonDecode(productResponse.body);
              // Backend trả về có thể là List hoặc Map
              final productInfo = productData is List && productData.isNotEmpty
                  ? productData[0]
                  : productData;
              
              final imageUrl = productInfo['anh'] as String?;
              
              if (imageUrl != null && imageUrl.isNotEmpty) {
                // Download ảnh từ URL
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
        
        productsWithImages.add({
          'productId': productId,
          'productName': productName,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'price': price,
          'similarity': similarity,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        });
      }
    } catch (e) {
      print('Error fetching product images: $e');
    }
    
    return productsWithImages;
  }

  /// Lấy sản phẩm theo category từ backend
  Future<List<Map<String, dynamic>>> _getProductsByCategory(String categoryId, {int limit = 3}) async {
    try {
      final products = await _categoryApi.getProductsByCategory(categoryId);
      
      if (products.isEmpty) {
        return [];
      }
      
      // Lấy limit sản phẩm đầu tiên và fetch images
      final limitedProducts = products.take(limit).toList();
      final List<Map<String, dynamic>> productsWithImages = [];
      
      for (var product in limitedProducts) {
        String? imageData;
        String? imageMimeType;
        
        // Lấy ảnh từ product
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
        
        productsWithImages.add({
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        });
      }
      
      return productsWithImages;
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  /// Lấy sản phẩm fallback (phổ biến) khi không tìm thấy
  Future<List<Map<String, dynamic>>> _getFallbackProducts({int limit = 3}) async {
    try {
      // Lấy tất cả sản phẩm và chọn ngẫu nhiên hoặc sản phẩm có số lượng tồn cao
      final products = await _productApi.getProducts();
      
      if (products.isEmpty) {
        return [];
      }
      
      // Sắp xếp theo số lượng tồn (sản phẩm có nhiều tồn kho thường phổ biến hơn)
      products.sort((a, b) => b.soLuongTon.compareTo(a.soLuongTon));
      
      // Lấy limit sản phẩm đầu tiên
      final limitedProducts = products.take(limit).toList();
      final List<Map<String, dynamic>> productsWithImages = [];
      
      for (var product in limitedProducts) {
        String? imageData;
        String? imageMimeType;
        
        // Lấy ảnh từ product
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
        
        productsWithImages.add({
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
          'imageData': imageData,
          'imageMimeType': imageMimeType,
        });
      }
      
      return productsWithImages;
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
      
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: messageContent,
      );
    } catch (e) {
      print('Error sending fallback products: $e');
      await _chatApi.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: 'Xin lỗi, có lỗi xảy ra khi tìm kiếm sản phẩm.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TỐI ƯU: Cache MediaQuery một lần
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
            // TỐI ƯU: Sử dụng ValueListenableBuilder thay vì setState toàn màn hình
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
                        onRefresh: () => _loadMessages(),
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

