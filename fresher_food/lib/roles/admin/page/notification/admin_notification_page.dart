import 'package:flutter/material.dart';
import 'package:fresher_food/models/Notification.dart' as AppNotification;
import 'package:fresher_food/services/api/notification_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/admin/page/order_manager/quanlydonhang.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

/// Màn hình hiển thị danh sách thông báo cho admin
class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final NotificationApi _notificationApi = NotificationApi();
  List<AppNotification.Notification> _notifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  String? _maAdmin;

  /// Khối khởi tạo: Load thông tin admin và danh sách thông báo
  @override
  void initState() {
    super.initState();
    _loadAdminAndNotifications();
  }

  /// Khối chức năng: Load thông tin admin và danh sách thông báo
  Future<void> _loadAdminAndNotifications() async {
    try {
      final user = await UserApi().getCurrentUser();
      if (user != null) {
        setState(() {
          _maAdmin = user.maTaiKhoan;
        });
        await _loadNotifications();
      }
    } catch (e) {
      print('Error loading admin info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Khối chức năng: Load danh sách thông báo
  Future<void> _loadNotifications() async {
    if (_maAdmin == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationApi.getNotificationsByAdmin(
        _maAdmin!,
        unreadOnly: _showUnreadOnly,
      );
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Khối chức năng: Đánh dấu thông báo đã đọc và navigate đến đơn hàng nếu có
  Future<void> _handleNotificationTap(AppNotification.Notification notification) async {
    // Đánh dấu đã đọc nếu chưa đọc
    if (!notification.daDoc) {
      final success = await _notificationApi.markAsRead(notification.maThongBao);
      if (success) {
        setState(() {
          final updatedNotification = AppNotification.Notification(
            maThongBao: notification.maThongBao,
            loaiThongBao: notification.loaiThongBao,
            maDonHang: notification.maDonHang,
            maNguoiNhan: notification.maNguoiNhan,
            tieuDe: notification.tieuDe,
            noiDung: notification.noiDung,
            daDoc: true,
            ngayTao: notification.ngayTao,
            ngayDoc: DateTime.now(),
          );
          // Cập nhật trong list
          final index = _notifications.indexWhere(
            (n) => n.maThongBao == notification.maThongBao,
          );
          if (index != -1) {
            _notifications[index] = updatedNotification;
          }
        });
      }
    }

    // Navigate đến đơn hàng nếu có mã đơn hàng
    if (notification.maDonHang != null && notification.maDonHang!.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuanLyDonHangScreen(),
          ),
        );
      }
    }
  }

  /// Khối chức năng: Đánh dấu tất cả thông báo đã đọc
  Future<void> _markAllAsRead() async {
    if (_maAdmin == null) return;

    final success = await _notificationApi.markAllAsRead(_maAdmin!);
    if (success) {
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu tất cả thông báo đã đọc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi đánh dấu đã đọc'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Khối giao diện: Format thời gian hiển thị
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Khối giao diện: Icon theo loại thông báo
  IconData _getNotificationIcon(String loaiThongBao) {
    switch (loaiThongBao) {
      case 'NewOrder':
        return Iconsax.shopping_bag;
      case 'OrderStatusChanged':
        return Iconsax.info_circle;
      default:
        return Iconsax.notification;
    }
  }

  /// Khối giao diện: Màu icon theo loại thông báo
  Color _getNotificationColor(String loaiThongBao) {
    switch (loaiThongBao) {
      case 'NewOrder':
        return Colors.green;
      case 'OrderStatusChanged':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  /// Khối giao diện chính: Build widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Toggle filter
          IconButton(
            icon: Icon(_showUnreadOnly ? Iconsax.eye : Iconsax.eye_slash),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              _loadNotifications();
            },
            tooltip: _showUnreadOnly ? 'Hiển thị tất cả' : 'Chỉ hiển thị chưa đọc',
          ),
          // Đánh dấu tất cả đã đọc
          if (_notifications.any((n) => !n.daDoc))
            IconButton(
              icon: const Icon(Iconsax.tick_circle),
              onPressed: _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.notification,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showUnreadOnly
                            ? 'Không có thông báo chưa đọc'
                            : 'Không có thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  /// Khối giao diện: Build card thông báo
  Widget _buildNotificationCard(AppNotification.Notification notification) {
    final isUnread = !notification.daDoc;
    final iconColor = _getNotificationColor(notification.loaiThongBao);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? Colors.blue[50] : null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification.loaiThongBao),
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          notification.tieuDe,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.noiDung != null && notification.noiDung!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notification.noiDung!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.ngayTao),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }
}

