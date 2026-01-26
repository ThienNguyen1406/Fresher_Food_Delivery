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
  List<Chat> _chats = [];
  bool _isLoading = true;
  User? _currentUser;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
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

  /// Tạo cuộc trò chuyện mới
  Future<void> _createNewChat() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để tạo cuộc trò chuyện'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _chatApi.createChat(
        maNguoiDung: _currentUser!.maTaiKhoan,
        tieuDe: 'Cuộc trò chuyện mới',
        noiDungTinNhanDau: null,
      );

      if (result != null && result['maChat'] != null) {
        if (mounted) {
          // Reload danh sách chat trước
          await _loadData();
          
          // Chuyển đến trang chat detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                maChat: result['maChat'],
                currentUserId: _currentUser!.maTaiKhoan,
              ),
            ),
          ).then((_) => _loadData());
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo cuộc trò chuyện: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _isLoading ? null : _createNewChat,
            tooltip: 'Tạo cuộc trò chuyện mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createNewChat,
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tạo cuộc trò chuyện mới',
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
                                return Dismissible(
                                  key: Key(chat.maChat),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
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
                                    ) ?? false;
                                  },
                                  onDismissed: (direction) async {
                                    if (_currentUser != null) {
                                      final success = await _chatApi.deleteChat(
                                        chat.maChat,
                                        _currentUser!.maTaiKhoan,
                                      );
                                      if (success && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã xóa cuộc trò chuyện'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        _loadData();
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Không thể xóa cuộc trò chuyện'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        _loadData(); // Reload để hiển thị lại chat đã bị xóa
                                      }
                                    }
                                  },
                                  child: _buildChatItem(chat, localizations),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final hasUnread = (chat.soTinNhanChuaDoc ?? 0) > 0;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    // Tạo tiêu đề phân biệt: nếu TieuDe là null hoặc "Cuộc trò chuyện mới", dùng preview tin nhắn
    String displayTitle;
    if (chat.tieuDe == null || 
        chat.tieuDe!.isEmpty || 
        chat.tieuDe == 'Cuộc trò chuyện mới' ||
        chat.tieuDe == localizations.supportChat) {
      // Dùng preview tin nhắn cuối hoặc tin nhắn đầu tiên
      if (chat.tinNhanCuoi != null && chat.tinNhanCuoi!.isNotEmpty) {
        displayTitle = chat.tinNhanCuoi!.length > 40 
            ? '${chat.tinNhanCuoi!.substring(0, 40)}...' 
            : chat.tinNhanCuoi!;
      } else {
        // Nếu không có tin nhắn, dùng ngày tạo để phân biệt
        displayTitle = 'Cuộc trò chuyện ${dateFormat.format(chat.ngayTao)}';
      }
    } else {
      displayTitle = chat.tieuDe!;
    }
    
    // Tạo màu avatar khác nhau dựa trên maChat để phân biệt
    final avatarColor = _getAvatarColor(chat.maChat);
    final avatarIcon = _getAvatarIcon(chat.maChat);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: hasUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUnread 
            ? BorderSide(color: theme.primaryColor.withOpacity(0.3), width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColor.withOpacity(0.15),
              child: Icon(
                avatarIcon,
                color: avatarColor,
                size: 28,
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                  color: hasUnread ? theme.primaryColor : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                chat.ngayTinNhanCuoi != null
                    ? timeFormat.format(chat.ngayTinNhanCuoi!)
                    : timeFormat.format(chat.ngayTao),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if (chat.tinNhanCuoi != null && chat.tinNhanCuoi!.isNotEmpty)
              Text(
                chat.tinNhanCuoi!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              )
            else
              Text(
                localizations.noMessages,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  chat.ngayTinNhanCuoi != null
                      ? '${dateFormat.format(chat.ngayTinNhanCuoi!)}'
                      : 'Tạo: ${dateFormat.format(chat.ngayTao)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chat.soTinNhanChuaDoc}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: hasUnread
            ? Icon(
                Icons.chevron_right,
                color: theme.primaryColor,
              )
            : Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
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

  // Tạo màu avatar khác nhau dựa trên maChat để phân biệt
  Color _getAvatarColor(String maChat) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final hash = maChat.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Tạo icon khác nhau dựa trên maChat để phân biệt
  IconData _getAvatarIcon(String maChat) {
    final icons = [
      Icons.chat_bubble,
      Icons.support_agent,
      Icons.help_outline,
      Icons.question_answer,
      Icons.forum,
      Icons.message,
      Icons.chat_bubble_outline,
      Icons.contact_support,
    ];
    final hash = maChat.hashCode;
    return icons[hash.abs() % icons.length];
  }
}
