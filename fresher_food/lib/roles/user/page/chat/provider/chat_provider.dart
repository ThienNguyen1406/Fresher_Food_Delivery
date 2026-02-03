import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/roles/user/page/chat/provider/chat_state.dart';
import 'package:fresher_food/roles/user/page/chat/provider/chat_service.dart';
import 'dart:async';
import 'dart:io';

/// Provider quản lý trạng thái chat để tránh render nhiều lần
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  // State
  final String maChat;
  final String currentUserId;
  
  ChatState _state = const ChatState();
  ChatState get state => _state;

  // Getters từ state
  List<Message> get messages => _state.messages;
  bool get isLoading => _state.isLoading;
  bool get isLoadingMore => _state.isLoadingMore;
  bool get hasMoreMessages => _state.hasMoreMessages;
  bool get isSending => _state.isSending;
  bool get isUploadingFile => _state.isUploadingFile;
  bool get isWaitingForBotResponse => _state.isWaitingForBotResponse;
  String? get selectedFileId => _state.selectedFileId;
  String? get selectedImagePath => _state.selectedImagePath;

  // Internal state (không cần notify)
  bool _isWaitingForBot = false;
  bool _isPageVisible = true;
  bool _isLoadingMessages = false;
  DateTime? _lastLoadTime;
  
  // Timers
  Timer? _refreshTimer;
  Timer? _botResponseWaitTimer;

  ChatProvider({
    required this.maChat,
    required this.currentUserId,
  }) {
    _initialize();
  }

  void _initialize() {
    loadMessages();
    _startRefreshTimer();
  }

  /// Update state và notify listeners
  void _updateState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Set page visibility
  void setPageVisible(bool visible) {
    if (_isPageVisible != visible) {
      _isPageVisible = visible;
      if (!visible) {
        _botResponseWaitTimer?.cancel();
      }
    }
  }

  /// Load messages
  Future<void> loadMessages({bool silent = false}) async {
    // Debounce: Tránh load quá nhiều lần trong thời gian ngắn
    final now = DateTime.now();
    if (_isLoadingMessages) {
      print('⏳ Already loading messages, skipping...');
      return;
    }
    
    if (_lastLoadTime != null && !silent) {
      final timeSinceLastLoad = now.difference(_lastLoadTime!);
      if (timeSinceLastLoad.inMilliseconds < 500) {
        print('⏳ Too soon since last load, skipping...');
        return;
      }
    }
    
    _isLoadingMessages = true;
    _lastLoadTime = now;
    
    if (!silent) {
      _updateState(_state.loading());
    }

    try {
      final result = await _chatService.getMessages(
        maChat: maChat,
        limit: 30,
      );
      
      final newMessages = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;
      
      // Reverse messages để hiển thị mới nhất ở dưới
      final reversedMessages = newMessages.reversed.toList();
      
      // Nếu đang đợi bot response, merge thay vì replace để giữ optimistic messages
      if (_isWaitingForBot) {
        final currentMessages = List<Message>.from(_state.messages);
        
        // Nếu có messages hiện tại, merge
        if (currentMessages.isNotEmpty) {
          final existingIds = currentMessages.map((m) => m.maTinNhan).toSet();
          
          // Chỉ thêm messages mới (chưa có trong list)
          final messagesToAdd = <Message>[];
          for (var newMsg in reversedMessages) {
            if (!existingIds.contains(newMsg.maTinNhan)) {
              messagesToAdd.add(newMsg);
            }
          }
          
          // Nếu có messages mới, merge và cập nhật
          if (messagesToAdd.isNotEmpty) {
            final mergedMessages = [...messagesToAdd, ...currentMessages];
            _updateState(_state.copyWith(
              messages: mergedMessages,
              isLoading: false,
              hasMoreMessages: hasMore,
            ));
            
            print('✅ New messages detected: ${messagesToAdd.length} new, total: ${mergedMessages.length}');
            
            // Kiểm tra nếu có bot response trong messages mới
            final hasBotResponse = messagesToAdd.any((msg) => 
              msg.loaiNguoiGui == 'Admin' || 
              msg.maNguoiGui == 'BOT' || 
              msg.maNguoiGui == 'Bot'
            );
            
            if (hasBotResponse) {
              print('✅ Bot response found in new messages!');
            }
          } else {
            // Nếu không có messages mới, vẫn cập nhật để đảm bảo UI sync
            _updateState(_state.copyWith(
              isLoading: false,
              hasMoreMessages: hasMore,
            ));
          }
        } else {
          // Chưa có messages, set trực tiếp
          _updateState(_state.success(reversedMessages, hasMore: hasMore));
        }
      } else {
        // Không đợi bot response, set trực tiếp
        _updateState(_state.success(reversedMessages, hasMore: hasMore));
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      if (!silent) {
        _updateState(_state.error());
      }
    } finally {
      _isLoadingMessages = false;
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_state.isLoadingMore || !_state.hasMoreMessages || _state.messages.isEmpty) return;

    _updateState(_state.copyWith(isLoadingMore: true));

    try {
      final oldestMessage = _state.messages.last;
      
      final result = await _chatService.getMessages(
        maChat: maChat,
        limit: 20,
        beforeMessageId: oldestMessage.maTinNhan,
      );

      final olderMessages = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;

      if (olderMessages.isNotEmpty) {
        final updatedMessages = [..._state.messages, ...olderMessages.reversed];
        _updateState(_state.copyWith(
          messages: updatedMessages,
          isLoadingMore: false,
          hasMoreMessages: hasMore,
        ));
      } else {
        _updateState(_state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
      }
    } catch (e) {
      print('Error loading more messages: $e');
      _updateState(_state.copyWith(isLoadingMore: false));
    }
  }

  /// Send message
  Future<bool> sendMessage(String text, {String? fileId}) async {
    if (_state.isSending) return false;
    
    _updateState(_state.copyWith(isSending: true));

    try {
      // Add optimistic message
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = Message(
        maTinNhan: tempMessageId,
        maChat: maChat,
        maNguoiGui: currentUserId,
        loaiNguoiGui: 'User',
        noiDung: text,
        ngayGui: DateTime.now(),
        daDoc: false,
      );
      
      final updatedMessages = [optimisticMessage, ..._state.messages];
      _updateState(_state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      final success = await _chatService.sendMessage(
        maChat: maChat,
        maNguoiGui: currentUserId,
        loaiNguoiGui: 'User',
        noiDung: text,
      );

      if (success) {
        // Đợi một chút để backend xử lý message
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Load messages một lần để đảm bảo sync
        await loadMessages(silent: true);
        
        // Start waiting for bot response
        _waitForBotResponse();
      } else {
        // Remove optimistic message on failure
        final messagesWithoutTemp = updatedMessages.where((m) => m.maTinNhan != tempMessageId).toList();
        _updateState(_state.copyWith(
          messages: messagesWithoutTemp,
          isSending: false,
        ));
      }

      _updateState(_state.copyWith(isSending: false));
      return success;
    } catch (e) {
      print('Error sending message: $e');
      _updateState(_state.copyWith(isSending: false));
      return false;
    }
  }

  /// Wait for bot response
  void _waitForBotResponse() {
    _botResponseWaitTimer?.cancel();
    
    _isWaitingForBot = true;
    _updateState(_state.copyWith(isWaitingForBotResponse: true));
    
    // Check bot response mỗi 2s, tối đa 10 lần (20s)
    int attempts = 0;
    const maxAttempts = 10;
    int lastMessageCount = _state.messages.length;
    
    _botResponseWaitTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      attempts++;
      if (_isPageVisible) {
        try {
          // Load messages và đợi kết quả
          await loadMessages(silent: true);
          
          // Kiểm tra nếu có messages mới (bot đã trả lời)
          final currentMessageCount = _state.messages.length;
          final hasNewMessages = currentMessageCount > lastMessageCount;
          
          if (hasNewMessages) {
            lastMessageCount = currentMessageCount;
          }
          
          // Kiểm tra lại sau khi load xong
          if (_state.messages.isNotEmpty) {
            final lastMessage = _state.messages.first;
            // Kiểm tra nếu bot đã trả lời (Admin, BOT, hoặc Bot)
            final isBotResponse = lastMessage.loaiNguoiGui == 'Admin' || 
                                 lastMessage.maNguoiGui == 'BOT' ||
                                 lastMessage.maNguoiGui == 'Bot' ||
                                 lastMessage.loaiNguoiGui == 'Bot';
            
            if (isBotResponse || hasNewMessages) {
              print('✅ Bot response detected: ${lastMessage.maTinNhan}, sender: ${lastMessage.maNguoiGui}, new messages: $hasNewMessages');
              
              _isWaitingForBot = false;
              _updateState(_state.copyWith(isWaitingForBotResponse: false));
              timer.cancel();
              
              // Force notify để đảm bảo UI cập nhật
              _startRefreshTimer();
              return;
            }
          }
        } catch (e) {
          print('❌ Error checking bot response: $e');
        }
      }
      
      if (attempts >= maxAttempts) {
        print('⚠️ Bot response timeout after $maxAttempts attempts');
        _isWaitingForBot = false;
        _updateState(_state.copyWith(isWaitingForBotResponse: false));
        timer.cancel();
        _startRefreshTimer();
        
        // Load messages một lần cuối để đảm bảo sync
        await loadMessages(silent: true);
      }
    });
  }

  /// Start refresh timer
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    
    // Refresh mỗi 30s để đảm bảo sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isPageVisible && !_state.isSending && !_isWaitingForBot && !_isLoadingMessages) {
        loadMessages(silent: true);
      }
    });
  }

  /// Set selected file
  void setSelectedFile(String? fileId, File? image) {
    _updateState(_state.copyWith(
      selectedFileId: fileId,
      selectedImagePath: image?.path,
    ));
  }

  /// Set uploading file state
  void setUploadingFile(bool uploading) {
    _updateState(_state.copyWith(isUploadingFile: uploading));
  }

  /// Sync optimistic message với real message từ server
  Future<void> syncOptimisticMessage(String tempMessageId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await _chatService.getMessages(
        maChat: maChat,
        limit: 3,
      );
      
      final newMessages = result['messages'] as List<Message>;
      final reversedNewMessages = newMessages.reversed.toList();
      
      final currentMessages = List<Message>.from(_state.messages);
      final tempIndex = currentMessages.indexWhere((m) => m.maTinNhan == tempMessageId);
      
      if (tempIndex != -1 && reversedNewMessages.isNotEmpty) {
        final realMessage = reversedNewMessages.firstWhere(
          (m) => m.maNguoiGui == currentUserId && 
                 m.noiDung.trim() == currentMessages[tempIndex].noiDung.trim(),
          orElse: () => reversedNewMessages.first,
        );
        
        currentMessages[tempIndex] = realMessage;
        _updateState(_state.copyWith(messages: currentMessages));
      }
    } catch (e) {
      print('Error syncing optimistic message: $e');
    }
  }

  /// Get chat service (để sử dụng các method phức tạp như search products by image)
  ChatService get chatService => _chatService;

  /// Update messages directly (for complex operations like image search)
  void updateMessages(List<Message> messages) {
    _updateState(_state.copyWith(messages: messages));
  }

  /// Add message to the beginning of the list
  void addMessage(Message message) {
    final updatedMessages = [message, ..._state.messages];
    _updateState(_state.copyWith(messages: updatedMessages));
  }

  /// Update waiting for bot response state
  void setWaitingForBotResponse(bool waiting) {
    _updateState(_state.copyWith(isWaitingForBotResponse: waiting));
  }

  /// Update uploading file and waiting for bot response states
  void setUploadingAndWaiting({bool? uploading, bool? waiting}) {
    _updateState(_state.copyWith(
      isUploadingFile: uploading ?? _state.isUploadingFile,
      isWaitingForBotResponse: waiting ?? _state.isWaitingForBotResponse,
    ));
  }

  /// Cleanup
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _botResponseWaitTimer?.cancel();
    super.dispose();
  }
}
