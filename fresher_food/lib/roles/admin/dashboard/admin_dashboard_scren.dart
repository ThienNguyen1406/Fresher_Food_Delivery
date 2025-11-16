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
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userInfo;
  int _totalUnreadMessages = 0;
  final ChatApi _chatApi = ChatApi();
  Timer? _refreshTimer;

  // Danh sách màn hình quản lý
  late final List<Map<String, dynamic>> _screens = [
    {
      'title': 'Trang chủ',
      'screen': const ThongKeScreen(),
      'icon': Iconsax.home
    },
    {
      'title': 'Quản lý sản phẩm',
      'screen': const QuanLySanPhamScreen(),
      'icon': Iconsax.box
    },
    {
      'title': 'Quản lý danh mục',
      'screen': const QuanLyDanhMucScreen(),
      'icon': Iconsax.category
    },
    {
      'title': 'Quản lý đơn hàng',
      'screen': const QuanLyDonHangScreen(),
      'icon': Iconsax.shopping_bag
    },
    {
      'title': 'Quản lý người dùng',
      'screen': const QuanLyNguoiDungScreen(),
      'icon': Iconsax.profile_2user
    },
    {
      'title': 'Quản lý mã giảm giá',
      'screen': const QuanLyPhieuGiamGiaScreen(),
      'icon': Iconsax.discount_shape
    },
    {
      'title': 'Quản lý chat',
      'screen': const AdminChatListPage(),
      'icon': Iconsax.message
    },
    {
      'title': 'Quản lý khuyến mãi',
      'screen': const QuanLyKhuyenMaiScreen(),
      'icon': Iconsax.magicpen
    },
    {
      'title': 'Cài đặt',
      'screen': const CaiDatScreen(),
      'icon': Iconsax.setting
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnreadMessagesCount();
    // Auto refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadUnreadMessagesCount();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final screen = _screens[_selectedIndex]['screen'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: screen ?? _buildComingSoonScreen(),
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

  Widget _buildComingSoonScreen() {
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
            'Tính năng đang phát triển',
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

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _screens[_selectedIndex]['title'],
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
        Stack(
          children: [
            IconButton(
              icon: const Icon(Iconsax.notification),
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
                    color: Colors.red,
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

  Widget _buildDrawer() {
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
                  _userInfo?['tenTaiKhoan'] ?? 'Quản trị viên',
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
            _screens.length,
            (index) {
              final isChatMenu = index == 6; // Index of "Quản lý chat"
              return ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      _screens[index]['icon'],
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
                            _totalUnreadMessages > 99 ? '99+' : '$_totalUnreadMessages',
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
                  _screens[index]['title'],
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
                          _totalUnreadMessages > 99 ? '99+' : '$_totalUnreadMessages',
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
