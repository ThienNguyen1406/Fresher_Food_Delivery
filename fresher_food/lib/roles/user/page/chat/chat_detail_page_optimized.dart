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

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  final ChatApi _chatApi = ChatApi();
  final RagApi _ragApi = RagApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // TỐI ƯU: Sử dụng ValueNotifier thay vì setState toàn màn hình
  final ValueNotifier<List<Message>> _messagesNotifier =
      ValueNotifier<List<Message>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasMoreMessagesNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isUploadingFileNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isWaitingForBotResponseNotifier =
      ValueNotifier<bool>(false);

  // Getters để tương thích với code cũ
  List<Message> get _messages => _messagesNotifier.value;
  bool get _isLoading => _isLoadingNotifier.value;
  bool get _isLoadingMore => _isLoadingMoreNotifier.value;
  bool get _hasMoreMessages => _hasMoreMessagesNotifier.value;
  bool get _isSending => _isSendingNotifier.value;
  bool get _isUploadingFile => _isUploadingFileNotifier.value;
  bool get _isWaitingForBotResponse => _isWaitingForBotResponseNotifier.value;

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
    _scrollController.addListener(_onScroll);

    // TỐI ƯU: Tăng interval từ 5s lên 8s để giảm API calls
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _isPageVisible) {
        _loadNewMessages();
      }
    });
  }

  void _onScroll() {
    final now = DateTime.now();
    if (_lastScrollCheck != null &&
        now.difference(_lastScrollCheck!).inMilliseconds < 200) {
      return;
    }
    _lastScrollCheck = now;

    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }

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
    _isPageVisible = state == AppLifecycleState.resumed;
    if (!_isPageVisible) {
      _botResponseWaitTimer?.cancel();
    }
  }

  void _waitForBotResponse() {
    _botResponseWaitTimer?.cancel();

    // TỐI ƯU: Chỉ update flag, không rebuild toàn màn hình
    _isWaitingForBotResponseNotifier.value = true;

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
    const maxAttempts = 8;

    _botResponseWaitTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      attempts++;
      if (mounted && _isPageVisible) {
        _loadNewMessages();

        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          if (lastMessage.loaiNguoiGui == 'Admin' ||
              lastMessage.maNguoiGui == 'BOT') {
            _isWaitingForBotResponseNotifier.value = false;
            timer.cancel();
            return;
          }
        }
      }

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

        await _chatApi.markAsRead(
          maChat: widget.maChat,
          maNguoiDoc: widget.currentUserId,
        );

        if (newMessages.isNotEmpty && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
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

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _messages.isEmpty) return;

    _isLoadingMoreNotifier.value = true;

    try {
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
          final currentScrollPosition = _scrollController.position.pixels;
          final currentMaxScroll = _scrollController.position.maxScrollExtent;

          // TỐI ƯU: Update ValueNotifier thay vì setState
          final updatedMessages = [...olderMessages, ..._messages];
          _messagesNotifier.value = updatedMessages;
          _hasMoreMessagesNotifier.value = hasMore;
          _isLoadingMoreNotifier.value = false;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final newMaxScroll = _scrollController.position.maxScrollExtent;
              final scrollDifference = newMaxScroll - currentMaxScroll;
              _scrollController
                  .jumpTo(currentScrollPosition + scrollDifference);
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

  /// TỐI ƯU: Chỉ update messages nếu có thay đổi thực sự
  Future<void> _loadNewMessages() async {
    if (!_isPageVisible) return;

    try {
      final result = await _chatApi.getMessages(
        maChat: widget.maChat,
        limit: 10,
      );

      if (mounted) {
        final newMessages = result['messages'] as List<Message>;
        final hasMore = result['hasMore'] as bool;

        // TỐI ƯU: So sánh reference và chỉ update nếu thay đổi
        final currentMessages = _messages;
        if (newMessages.length != currentMessages.length ||
            (newMessages.isNotEmpty &&
                currentMessages.isNotEmpty &&
                newMessages.last.maTinNhan != currentMessages.last.maTinNhan)) {
          final oldLastMessageId = currentMessages.isNotEmpty
              ? currentMessages.last.maTinNhan
              : null;

          bool botResponded = false;
          if (newMessages.isNotEmpty) {
            final lastMessage = newMessages.last;
            if (lastMessage.loaiNguoiGui == 'Admin' ||
                lastMessage.maNguoiGui == 'BOT') {
              botResponded = true;
            }
          }

          // TỐI ƯU: Chỉ update ValueNotifier, không rebuild toàn màn hình
          _messagesNotifier.value = newMessages;
          _hasMoreMessagesNotifier.value = hasMore;
          if (botResponded) {
            _isWaitingForBotResponseNotifier.value = false;
          }

          if (oldLastMessageId != null &&
              newMessages.isNotEmpty &&
              newMessages.last.maTinNhan != oldLastMessageId &&
              _scrollController.hasClients) {
            final isNearBottom = _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200;
            if (isNearBottom) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }

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
      // Silent fail
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _isSendingNotifier.value = true;

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

          _messageController.clear();
          _loadNewMessages();
          _waitForBotResponse();
        } else {
          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );
          _messageController.clear();
          _loadNewMessages();
          _waitForBotResponse();
        }
      } else {
        final success = await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: text,
        );

        if (success && mounted) {
          _messageController.clear();
          _loadNewMessages();
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

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final response = await _ragApi.uploadDocument(file);

        if (mounted) {
          Navigator.pop(context);
        }

        if (response != null && mounted) {
          _selectedFileId = response['file_id'];
          _isUploadingFileNotifier.value = false;

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
        Navigator.pop(context);
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
      appBar: _buildAppBar(localizations),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF5F7FA),
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
            // TỐI ƯU: Tách message input thành widget riêng với ValueListenableBuilder
            _buildMessageInput(localizations, theme),
          ],
        ),
      ),
    );
  }

  // TỐI ƯU: Tách AppBar thành widget riêng với const
  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
    return AppBar(
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
        ValueListenableBuilder<bool>(
          valueListenable: _isUploadingFileNotifier,
          builder: (context, isUploading, _) {
            return Container(
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
                onPressed: isUploading ? null : _uploadDocument,
                tooltip: 'Upload file để hỏi đáp',
              ),
            );
          },
        ),
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
    );
  }

  // TỐI ƯU: Widget const cho loading
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

  // TỐI ƯU: Widget const cho empty state
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      reverse: false,
                      itemCount: messages.length + (isWaiting ? 1 : 0),
                      // TỐI ƯU: Tăng cacheExtent và thêm các flags
                      cacheExtent: 2000, // Tăng từ 1000 lên 2000
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        if (isWaiting && index == messages.length) {
                          return _TypingIndicatorWidget(
                              screenWidth: _cachedScreenWidth ?? 400);
                        }
                        final message = messages[index];
                        // TỐI ƯU: Sử dụng key ổn định và cache screenWidth
                        return MessageBubbleOptimized(
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
            // TỐI ƯU: ValueListenableBuilder cho upload button
            ValueListenableBuilder<bool>(
              valueListenable: _isUploadingFileNotifier,
              builder: (context, isUploading, _) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green),
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
                        ),
                );
              },
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
            // TỐI ƯU: ValueListenableBuilder cho send button
            ValueListenableBuilder<bool>(
              valueListenable: _isSendingNotifier,
              builder: (context, isSending, _) {
                return Container(
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
                      onTap: isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(22),
                      child: isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// TỐI ƯU: Widget bất biến với const và cache values
class MessageBubbleOptimized extends StatelessWidget {
  final Message message;
  final double screenWidth;
  final DateFormat timeFormat;

  const MessageBubbleOptimized({
    super.key,
    required this.message,
    required this.screenWidth,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    final maxWidth = screenWidth * 0.75;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            _BotAvatar(),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isFromUser
                    ? const LinearGradient(
                        colors: [Color(0xFF16A085), Color(0xFF138D75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isFromUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isFromUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFromUser ? Colors.green : Colors.black)
                        .withOpacity(0.1),
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
            _UserAvatar(),
          ],
        ],
      ),
    );
  }
}

/// TỐI ƯU: Tách avatar thành widget const riêng
class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
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
          const _BotAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
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
