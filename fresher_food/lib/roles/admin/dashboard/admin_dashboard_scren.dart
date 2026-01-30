import 'package:flutter/material.dart';
import 'package:fresher_food/roles/admin/page/category_manger/quanlydanhmuc_screen.dart';
import 'package:fresher_food/roles/admin/page/coupon_manger/quanlyphieugiamgia.dart';
import 'package:fresher_food/roles/admin/page/order_manager/quanlydonhang.dart';
import 'package:fresher_food/roles/admin/page/product_manager/quanlysanpham.dart';
import 'package:fresher_food/roles/admin/page/settings/settings_page.dart';
import 'package:fresher_food/roles/admin/page/statistical/thongke.dart';
import 'package:fresher_food/roles/admin/page/user_manager/quanlynguoidung.dart';
import 'package:fresher_food/roles/admin/page/chat_manager/admin_chat_list_page.dart';
import 'package:fresher_food/roles/admin/page/promotion_manager/quanlykhuyenmai.dart';
import 'package:fresher_food/roles/admin/page/rag_manager/rag_document_manager_page.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/notification_api.dart';
import 'package:fresher_food/roles/admin/page/notification/admin_notification_page.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

/// Màn hình dashboard admin - quản lý tất cả các chức năng quản trị
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userInfo;
  int _totalUnreadMessages = 0;
  int _totalUnreadNotifications = 0;
  final ChatApi _chatApi = ChatApi();
  final NotificationApi _notificationApi = NotificationApi();
  Timer? _refreshTimer;

  /// Lấy danh sách các màn hình quản lý với localization
  List<Map<String, dynamic>> _getScreens(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      {
        'title': localizations.adminHome,
        'screen': const ThongKeScreen(),
        'icon': Iconsax.home
      },
      {
        'title': localizations.adminProductManagement,
        'screen': const QuanLySanPhamScreen(),
        'icon': Iconsax.box
      },
      {
        'title': localizations.adminCategoryManagement,
        'screen': const QuanLyDanhMucScreen(),
        'icon': Iconsax.category
      },
      {
        'title': localizations.adminOrderManagement,
        'screen': const QuanLyDonHangScreen(),
        'icon': Iconsax.shopping_bag
      },
      {
        'title': localizations.adminUserManagement,
        'screen': const QuanLyNguoiDungScreen(),
        'icon': Iconsax.profile_2user
      },
      {
        'title': localizations.adminCouponManagement,
        'screen': const QuanLyPhieuGiamGiaScreen(),
        'icon': Iconsax.discount_shape
      },
      {
        'title': localizations.adminChatManagement,
        'screen': const AdminChatListPage(),
        'icon': Iconsax.message
      },
      {
        'title': localizations.adminPromotionManagement,
        'screen': const QuanLyKhuyenMaiScreen(),
        'icon': Iconsax.magicpen
      },
      {
        'title': 'AI hỗ trợ',
        'screen': const RagDocumentManagerPage(),
        'icon': Iconsax.document_text
      },
      {
        'title': localizations.adminSettings,
        'screen': const CaiDatScreen(),
        'icon': Iconsax.setting
      },
    ];
  }

  /// Load thông tin user, tin nhắn chưa đọc, thông báo chưa đọc và tự động refresh mỗi 10 giây
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnreadMessagesCount();
    _loadUnreadNotificationsCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadUnreadMessagesCount();
        _loadUnreadNotificationsCount();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Load thông tin người dùng admin
  Future<void> _loadUserInfo() async {
    try {
      final user = await UserApi().getUserInfo();
      setState(() {
        _userInfo = user;
      });
    } catch (e) {
      print('Lỗi load thông tin người dùng: $e');
    }
  }

  /// Load số lượng tin nhắn chưa đọc từ chat
  Future<void> _loadUnreadMessagesCount() async {
    try {
      final chats = await _chatApi.getAdminChats();
      final totalUnread = chats.fold<int>(
        0,
        (sum, chat) => sum + (chat.soTinNhanChuaDoc ?? 0),
      );
      if (mounted) {
        setState(() {
          _totalUnreadMessages = totalUnread;
        });
      }
    } catch (e) {
      print('Lỗi load số lượng tin nhắn chưa đọc: $e');
    }
  }

  /// Load số lượng thông báo chưa đọc
  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final user = await UserApi().getCurrentUser();
      if (user != null) {
        final count = await _notificationApi.getUnreadCount(user.maTaiKhoan);
        if (mounted) {
          setState(() {
            _totalUnreadNotifications = count;
          });
        }
      }
    } catch (e) {
      print('Lỗi load số lượng thông báo chưa đọc: $e');
    }
  }

  /// Hiển thị AppBar, Drawer và màn hình quản lý được chọn
  @override
  Widget build(BuildContext context) {
    final screens = _getScreens(context);
    final screen = screens[_selectedIndex]['screen'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: _buildAppBar(screens),
      drawer: _buildDrawer(screens, context),
      body: screen ?? _buildComingSoonScreen(context),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh unread count when screen changes
    if (_selectedIndex == 6) {
      _loadUnreadMessagesCount();
    }
  }

  Widget _buildComingSoonScreen(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.magicpen,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.featureUnderDevelopment,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(List<Map<String, dynamic>> screens) {
    return AppBar(
      title: Text(
        screens[_selectedIndex]['title'],
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [
        // Icon thông báo
        Stack(
          children: [
            IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () {
                // Navigate to notification page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminNotificationPage(),
                  ),
                ).then((_) {
                  // Refresh counts when returning from notification page
                  _loadUnreadNotificationsCount();
                });
              },
            ),
            if (_totalUnreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
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
                    _totalUnreadNotifications > 99
                        ? '99+'
                        : '$_totalUnreadNotifications',
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
        // Icon chat
        Stack(
          children: [
            IconButton(
              icon: const Icon(Iconsax.message),
              onPressed: () {
                // Navigate to chat list
                setState(() => _selectedIndex = 6); // Index of chat management
              },
            ),
            if (_totalUnreadMessages > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _totalUnreadMessages > 99 ? '99+' : '$_totalUnreadMessages',
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
      ],
    );
  }

  Widget _buildDrawer(
      List<Map<String, dynamic>> screens, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        children: [
          // Header Drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Iconsax.profile_circle,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userInfo?['tenTaiKhoan'] ?? localizations.adminAdministrator,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userInfo?['email'] ?? 'admin@example.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách menu
          ...List.generate(
            screens.length,
            (index) {
              final isChatMenu = index == 6; // Index of "Quản lý chat"
              return ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      screens[index]['icon'],
                      color: _selectedIndex == index
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade700,
                    ),
                    if (isChatMenu && _totalUnreadMessages > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            _totalUnreadMessages > 99
                                ? '99+'
                                : '$_totalUnreadMessages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  screens[index]['title'],
                  style: TextStyle(
                    fontWeight: _selectedIndex == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedIndex == index
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade700,
                  ),
                ),
                trailing: isChatMenu && _totalUnreadMessages > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _totalUnreadMessages > 99
                              ? '99+'
                              : '$_totalUnreadMessages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                selected: _selectedIndex == index,
                selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                  // Reload unread count when navigating to chat
                  if (isChatMenu) {
                    _loadUnreadMessagesCount();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaiDatScreen();
  }
}

class ThongKeManagementScreen extends StatelessWidget {
  const ThongKeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThongKeScreen();
  }
}

class DanhMucManagementScreen extends StatelessWidget {
  const DanhMucManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyDanhMucScreen();
  }
}

class DonHangManagementScreen extends StatelessWidget {
  const DonHangManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyDonHangScreen();
  }
}

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLySanPhamScreen();
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyNguoiDungScreen();
  }
}

class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyPhieuGiamGiaScreen();
  }
}
