import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/models/User.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'admin_chat_detail_page.dart';

class AdminChatListPage extends StatefulWidget {
  const AdminChatListPage({super.key});

  @override
  State<AdminChatListPage> createState() => _AdminChatListPageState();
}

class _AdminChatListPageState extends State<AdminChatListPage> {
  final ChatApi _chatApi = ChatApi();
  List<Chat> _chats = [];
  bool _isLoading = true;
  String? _error;
  User? _currentAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final admin = await UserApi().getCurrentUser();
      if (admin == null) {
        setState(() {
          _error = 'Please login as admin';
          _isLoading = false;
        });
        return;
      }

      _currentAdmin = admin;
      final chats = await _chatApi.getAdminChats();

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: localizations.retry,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                              // Admin có thể xóa chat của bất kỳ user nào
                              // Sử dụng maNguoiDung từ chat (không phải currentAdmin)
                              final success = await _chatApi.deleteChat(
                                chat.maChat,
                                chat.maNguoiDung,
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
                            },
                            child: _buildChatItem(chat, localizations),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatItem(Chat chat, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final hasUnread = (chat.soTinNhanChuaDoc ?? 0) > 0;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final userName = chat.nguoiDung?.hoTen ?? chat.maNguoiDung;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: hasUnread 
              ? Colors.red.withOpacity(0.1) 
              : theme.primaryColor.withOpacity(0.1),
          child: Icon(
            hasUnread ? Icons.chat_bubble : Icons.chat_bubble_outline,
            color: hasUnread ? Colors.red : theme.primaryColor,
          ),
        ),
        title: Text(
          chat.tieuDe ?? 'Chat với $userName',
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'User: $userName',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
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
              builder: (context) => AdminChatDetailPage(
                maChat: chat.maChat,
                currentAdminId: _currentAdmin?.maTaiKhoan ?? '',
                userName: userName,
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}

