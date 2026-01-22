import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/roles/admin/page/rag_manager/admin_rag_chat_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danh sách conversations của admin RAG
class AdminRagConversationListPage extends StatefulWidget {
  const AdminRagConversationListPage({super.key});

  @override
  State<AdminRagConversationListPage> createState() =>
      _AdminRagConversationListPageState();
}

class _AdminRagConversationListPageState
    extends State<AdminRagConversationListPage> {
  final ChatApi _chatApi = ChatApi();
  List<Chat> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  Timer? _refreshTimer;
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadConversations();
    // Auto refresh every 10 seconds để giảm tải (tăng từ 5 lên 10 giây)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadConversations(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('maTaiKhoan');
    });
    
    // Debug: Log để kiểm tra
    if (_currentUserId == null) {
      print('Warning: maTaiKhoan not found in SharedPreferences');
      print('Available keys: ${prefs.getKeys()}');
    } else {
      print('Current user ID loaded: $_currentUserId');
    }
  }

  Future<void> _loadConversations({bool silent = false}) async {
    // Reload user ID first
    await _loadCurrentUser();
    
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_currentUserId != null) {
        final conversations = await _chatApi.getUserChats(_currentUserId!);
        
        // Calculate total unread count
        final totalUnread = conversations.fold<int>(
          0,
          (sum, chat) => sum + (chat.soTinNhanChuaDoc ?? 0),
        );
        
        setState(() {
          _conversations = conversations;
          _totalUnreadCount = totalUnread;
          _isLoading = false;
        });
      } else {
        setState(() {
          _conversations = [];
          _totalUnreadCount = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewConversation() async {
    if (_currentUserId == null) {
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
      print('Creating conversation for user: $_currentUserId');
      final result = await _chatApi.createChat(
        maNguoiDung: _currentUserId!,
        tieuDe: 'Cuộc trò chuyện mới',
        noiDungTinNhanDau: null,
      );

      print('Create chat result: $result');

      if (result != null && result['maChat'] != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminRagChatPage(
                maChat: result['maChat'],
                currentUserId: _currentUserId!,
              ),
            ),
          ).then((_) => _loadConversations());
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo cuộc trò chuyện. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _showDeleteMenu(BuildContext context, Chat conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Xóa cuộc trò chuyện'),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.close_circle),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConversation(Chat conversation) async {

    // Hiển thị loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Đang xóa...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Admin có thể xóa bất kỳ chat nào, truyền maNguoiDung từ conversation
      final success = await _chatApi.deleteChat(conversation.maChat, conversation.maNguoiDung);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa cuộc trò chuyện thành công'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload danh sách
          _loadConversations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa cuộc trò chuyện. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Tìm kiếm thông tin',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            if (_totalUnreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _totalUnreadCount > 99 ? '99+' : '$_totalUnreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => _loadConversations(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.message_question,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc trò chuyện nào',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo cuộc trò chuyện mới để bắt đầu',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewConversation,
                        icon: const Icon(Iconsax.add),
                        label: const Text('Tạo cuộc trò chuyện mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return Dismissible(
                        key: Key(conversation.maChat),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Iconsax.trash,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text(
                                'Bạn có chắc chắn muốn xóa cuộc trò chuyện "${conversation.tieuDe ?? 'Cuộc trò chuyện'}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (direction) {
                          _deleteConversation(conversation);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          tileColor: (conversation.soTinNhanChuaDoc ?? 0) > 0
                              ? Colors.green.shade50
                              : null,
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  Iconsax.message_text,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              if ((conversation.soTinNhanChuaDoc ?? 0) > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      (conversation.soTinNhanChuaDoc ?? 0) > 99
                                          ? '99+'
                                          : '${conversation.soTinNhanChuaDoc}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.tieuDe ?? 'Cuộc trò chuyện',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: (conversation.soTinNhanChuaDoc ?? 0) > 0
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (conversation.tinNhanCuoi != null)
                                Text(
                                  conversation.tinNhanCuoi!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (conversation.soTinNhanChuaDoc ?? 0) > 0
                                        ? Colors.green.shade800
                                        : Colors.grey.shade700,
                                    fontWeight: (conversation.soTinNhanChuaDoc ?? 0) > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.clock,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(conversation.ngayTinNhanCuoi ??
                                        conversation.ngayTao),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Iconsax.arrow_right_3,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminRagChatPage(
                                  maChat: conversation.maChat,
                                  currentUserId: _currentUserId ?? '',
                                ),
                              ),
                            ).then((_) => _loadConversations());
                          },
                          onLongPress: () {
                            _showDeleteMenu(context, conversation);
                          },
                        ),
                      ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewConversation,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('Cuộc trò chuyện mới'),
      ),
    );
  }
}

