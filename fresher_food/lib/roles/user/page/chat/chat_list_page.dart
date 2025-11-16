import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/models/User.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatApi _chatApi = ChatApi();
  final UserApi _userApi = UserApi();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  List<Chat> _chats = [];
  bool _isLoading = true;
  bool _isSending = false;
  User? _currentUser;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _userApi.getCurrentUser();
      if (user == null) {
        setState(() {
          _error = 'Please login to view chats';
          _isLoading = false;
        });
        return;
      }

      _currentUser = user;
      print('Loading chats for user: ${user.maTaiKhoan}');
      final chats = await _chatApi.getUserChats(user.maTaiKhoan);
      print('Loaded ${chats.length} chats');

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Gửi tin nhắn từ input field
  Future<void> _sendMessageFromInput() async {
    if (_currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Tìm chat đang mở (Open) đầu tiên
      Chat? openChat = _chats.firstWhere(
        (chat) => chat.trangThai == 'Open',
        orElse: () => Chat(
          maChat: '',
          maNguoiDung: '',
          trangThai: 'Closed',
          ngayTao: DateTime.now(),
        ),
      );

      String? maChat;

      if (openChat.maChat.isEmpty) {
        // Chưa có chat nào đang mở, tạo chat mới
        final response = await _chatApi.createChat(
          maNguoiDung: _currentUser!.maTaiKhoan,
          tieuDe: null,
          noiDungTinNhanDau: text,
        );

        if (response != null && response['maChat'] != null) {
          maChat = response['maChat'];
        } else {
          throw Exception('Failed to create chat');
        }
      } else {
        // Có chat đang mở, gửi tin nhắn vào chat đó
        maChat = openChat.maChat;
        final success = await _chatApi.sendMessage(
          maChat: maChat,
          maNguoiGui: _currentUser!.maTaiKhoan,
          loaiNguoiGui: 'User',
          noiDung: text,
        );

        if (!success) {
          throw Exception('Failed to send message');
        }
      }

      // Xóa text trong input
      _messageController.clear();

      // Reload danh sách chat
      await _loadData();

      // Nếu có maChat, chuyển đến chat detail
      if (maChat != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              maChat: maChat!,
              currentUserId: _currentUser!.maTaiKhoan,
            ),
          ),
        ).then((_) => _loadData());
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
        title: Text(localizations.supportChat),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(localizations.retry),
                            ),
                          ],
                        ),
                      )
                    : _chats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  localizations.noChatsYet,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  localizations.startNewChat,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: _chats.length,
                              itemBuilder: (context, index) {
                                final chat = _chats[index];
                                return _buildChatItem(chat, localizations);
                              },
                            ),
                          ),
          ),
          // Input field luôn hiển thị ở dưới
          if (_currentUser != null) _buildMessageInput(localizations, theme),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final hasUnread = (chat.soTinNhanChuaDoc ?? 0) > 0;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.support_agent,
            color: theme.primaryColor,
          ),
        ),
        title: Text(
          chat.tieuDe ?? localizations.supportChat,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.tinNhanCuoi ?? localizations.noMessages,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chat.ngayTinNhanCuoi != null
                  ? '${dateFormat.format(chat.ngayTinNhanCuoi!)} ${timeFormat.format(chat.ngayTinNhanCuoi!)}'
                  : dateFormat.format(chat.ngayTao),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: hasUnread
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${chat.soTinNhanChuaDoc}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                maChat: chat.maChat,
                currentUserId: chat.maNguoiDung,
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  /// Widget input field để nhập tin nhắn
  Widget _buildMessageInput(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: localizations.enterYourMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessageFromInput(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
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
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessageFromInput,
                tooltip: localizations.send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
