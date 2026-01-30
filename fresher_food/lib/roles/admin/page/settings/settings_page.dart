import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/auth/auth_screen.dart' show AuthScreen;
import 'package:fresher_food/services/api/user_api.dart';
import 'package:iconsax/iconsax.dart';
import 'widgets/settings_loading_shimmer.dart';
import 'widgets/settings_login_required.dart';
import 'widgets/settings_user_card.dart';
import 'widgets/settings_menu_section.dart';
import 'widgets/settings_menu_option.dart';
import 'widgets/settings_animated_switch.dart';
import 'widgets/settings_logout_button.dart';
import 'widgets/settings_about_dialog.dart';

class CaiDatScreen extends StatefulWidget {
  const CaiDatScreen({super.key});

  @override
  State<CaiDatScreen> createState() => _CaiDatScreenState();
}

class _CaiDatScreenState extends State<CaiDatScreen> {
  final UserApi _apiService = UserApi();
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  
  // Cài đặt
  bool _thongBao = true;
  bool _darkMode = false;
  bool _autoBackup = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
    
    if (isLoggedIn) {
      await _loadUserInfo();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _apiService.getUserInfo();
      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.logout,
                      color: Colors.grey.shade700,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn có chắc muốn đăng xuất?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              final success = await _apiService.logout();
                              if (success) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi khi đăng xuất: $e'),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: _isLoading
          ? const SettingsLoadingShimmer()
          : _isLoggedIn
              ? _buildSettingsContent()
              : const SettingsLoginRequired(),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Info Card
          SettingsUserCard(userInfo: _userInfo),
          
          const SizedBox(height: 24),
          
          // Cài đặt chung
          SettingsMenuSection(
            title: 'Cài đặt chung',
            options: [
              SettingsMenuOption(
                icon: Iconsax.notification,
                title: 'Thông báo',
                subtitle: 'Nhận thông báo từ hệ thống',
                color: const Color(0xFF00C896),
                trailing: SettingsAnimatedSwitch(
                  value: _thongBao,
                  onChanged: (value) {
                    setState(() => _thongBao = value);
                  },
                ),
              ),
              SettingsMenuOption(
                icon: Iconsax.moon,
                title: 'Chế độ tối',
                subtitle: 'Giao diện tối cho ứng dụng',
                color: const Color(0xFF667EEA),
                trailing: SettingsAnimatedSwitch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                  },
                ),
              ),
              SettingsMenuOption(
                icon: Iconsax.cloud_add,
                title: 'Tự động sao lưu',
                subtitle: 'Tự động sao lưu dữ liệu',
                color: const Color(0xFFFFA726),
                trailing: SettingsAnimatedSwitch(
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() => _autoBackup = value);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Hỗ trợ & Giới thiệu
          SettingsMenuSection(
            title: 'Hỗ trợ & Giới thiệu',
            options: [
              SettingsMenuOption(
                icon: Iconsax.support,
                title: 'Trung tâm hỗ trợ',
                subtitle: 'Nhận trợ giúp và hướng dẫn',
                color: const Color(0xFFAB47BC),
                onTap: () => _showComingSoonSnackbar('Trung tâm hỗ trợ'),
              ),
              SettingsMenuOption(
                icon: Iconsax.info_circle,
                title: 'Giới thiệu ứng dụng',
                subtitle: 'Thông tin về phiên bản',
                color: const Color(0xFF26C6DA),
                onTap: _showAboutApp,
              ),
              SettingsMenuOption(
                icon: Iconsax.document,
                title: 'Điều khoản sử dụng',
                subtitle: 'Điều khoản và điều kiện',
                color: const Color(0xFF78909C),
                onTap: () => _showComingSoonSnackbar('Điều khoản sử dụng'),
              ),
              SettingsMenuOption(
                icon: Iconsax.security,
                title: 'Chính sách bảo mật',
                subtitle: 'Chính sách bảo mật thông tin',
                color: const Color(0xFF5C6BC0),
                onTap: () => _showComingSoonSnackbar('Chính sách bảo mật'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          SettingsLogoutButton(onLogout: _logout),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName - Tính năng đang phát triển'),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => const SettingsAboutDialog(),
    );
  }
}