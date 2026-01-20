import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/auth/login_screen.dart';
import 'package:fresher_food/roles/user/page/auth/register_screen.dart';
import 'package:fresher_food/roles/user/page/auth/register_with_phone_screen.dart';
import 'package:iconsax/iconsax.dart';

/// Màn hình xác thực chính - Quản lý đăng nhập và đăng ký
/// 
/// Màn hình này là điểm vào chính cho quá trình xác thực người dùng,
/// quản lý việc chuyển đổi giữa màn hình đăng nhập và đăng ký
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

/// State class cho AuthScreen
/// 
/// Quản lý trạng thái của vai trò hiện tại (user/admin) và màu sắc tương ứng
class _AuthScreenState extends State<AuthScreen> {
  // Vai trò hiện tại của người dùng (mặc định là 'user')
  String _currentRole = 'user';
  
  // Tên hiển thị của vai trò (mặc định là 'Khách Hàng')
  String _currentRoleName = 'Khách Hàng';
  
  // Màu chủ đạo tương ứng với vai trò (mặc định là màu xanh lá)
  Color _currentPrimaryColor = Colors.green;

  /// Callback được gọi khi người dùng thay đổi vai trò (từ LoginScreen)
  /// 
  /// Cập nhật trạng thái vai trò, tên vai trò và màu sắc tương ứng
  /// 
  /// [role] - Mã vai trò ('user' hoặc 'admin')
  /// [roleName] - Tên hiển thị của vai trò
  /// [primaryColor] - Màu chủ đạo cho vai trò này
  void _onRoleChanged(String role, String roleName, Color primaryColor) {
    setState(() {
      _currentRole = role;
      _currentRoleName = roleName;
      _currentPrimaryColor = primaryColor;
    });
  }

  /// Xây dựng giao diện màn hình xác thực
  /// 
  /// Tạo Scaffold với nền trắng và hiển thị _AuthTabContent
  /// để quản lý việc chuyển đổi giữa đăng nhập và đăng ký
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đặt nền trắng cho toàn bộ màn hình
      backgroundColor: Colors.white,
      body: Container(
        // Container với nền trắng để đảm bảo không có gradient
        color: Colors.white,
        child: SafeArea(
          // SafeArea đảm bảo nội dung không bị che bởi notch/status bar
          child: _AuthTabContent(
            role: _currentRole,
            roleName: _currentRoleName,
            primaryColor: _currentPrimaryColor,
            onRoleChanged: _onRoleChanged,
            showLogo: true,
          ),
        ),
      ),
    );
  }
}

/// Widget quản lý nội dung xác thực (đăng nhập/đăng ký)
/// 
/// Widget này chịu trách nhiệm hiển thị và chuyển đổi giữa
/// màn hình đăng nhập và màn hình đăng ký
class _AuthTabContent extends StatefulWidget {
  // Vai trò hiện tại được chọn
  final String role;
  
  // Tên hiển thị của vai trò
  final String roleName;
  
  // Màu chủ đạo cho giao diện
  final Color primaryColor;
  
  // Callback khi vai trò thay đổi
  final Function(String role, String roleName, Color primaryColor) onRoleChanged;
  
  // Có hiển thị logo hay không (hiện tại không sử dụng)
  final bool showLogo;

  const _AuthTabContent({
    required this.role,
    required this.roleName,
    required this.primaryColor,
    required this.onRoleChanged,
    this.showLogo = false,
  });

  @override
  State<_AuthTabContent> createState() => _AuthTabContentState();
}

/// State class cho _AuthTabContent
/// 
/// Quản lý trạng thái hiển thị (đăng nhập hay đăng ký)
class _AuthTabContentState extends State<_AuthTabContent> {
  // Biến trạng thái: true = hiển thị màn hình đăng nhập, false = hiển thị màn hình đăng ký
  bool _isLogin = true;

  /// Xây dựng giao diện dựa trên trạng thái hiện tại
  /// 
  /// Nếu _isLogin = true: Hiển thị logo và LoginScreen
  /// Nếu _isLogin = false: Hiển thị RegisterScreen (với logo có scroll animation)
  @override
  Widget build(BuildContext context) {
    if (_isLogin) {
      // ========== MÀN HÌNH ĐĂNG NHẬP ==========
      return Column(
        children: [
          // Container chứa logo - chỉ hiển thị khi đăng nhập
          Container(
            // Padding động dựa trên chiều cao màn hình (1% trên và dưới)
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.01,
              bottom: MediaQuery.of(context).size.height * 0.01,
            ),
            // Hiển thị logo từ assets
            child: Image.asset(
              "lib/assets/img/loginImg.png",
              // Chiều cao logo = 30% chiều cao màn hình
              height: MediaQuery.of(context).size.height * 0.30,
              // Giữ tỷ lệ khung hình của logo
              fit: BoxFit.contain,
            ),
          ),
          // Expanded để LoginScreen chiếm phần còn lại của màn hình
          Expanded(
            child: LoginScreen(
              // Truyền vai trò hiện tại
              role: widget.role,
              roleName: widget.roleName,
              primaryColor: widget.primaryColor,
              // Callback khi người dùng click "Đăng ký ngay" - chuyển sang màn hình đăng ký
              onSwitchToRegister: () {
                setState(() {
                  _isLogin = false;
                });
              },
              // Callback khi người dùng thay đổi vai trò (Admin/User) trong LoginScreen
              onRoleChanged: widget.onRoleChanged,
            ),
          ),
        ],
      );
    } else {
      // ========== MÀN HÌNH ĐĂNG KÝ ==========
      return Stack(
        children: [
          RegisterScreen(
            // Chỉ cho phép đăng ký với vai trò 'user' (không cho phép đăng ký admin)
            role: 'user',
            roleName: 'Khách Hàng',
            primaryColor: Colors.green,
            // Callback khi người dùng click "Đăng nhập ngay" - chuyển về màn hình đăng nhập
            onSwitchToLogin: () {
              setState(() {
                _isLogin = true;
              });
            },
            // Callback khi đăng ký thành công - tự động chuyển về màn hình đăng nhập
            onRegisterSuccess: () {
              setState(() {
                _isLogin = true;
              });
            },
            // Callback khi người dùng thay đổi vai trò (không sử dụng trong RegisterScreen)
            onRoleChanged: widget.onRoleChanged,
          ),
          // Button chuyển sang đăng ký bằng số điện thoại
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterWithPhoneScreen(
                          role: 'user',
                          roleName: 'Khách Hàng',
                          primaryColor: Colors.green,
                          onSwitchToLogin: () {
                            Navigator.pop(context);
                            setState(() {
                              _isLogin = true;
                            });
                          },
                          onRegisterSuccess: () {
                            Navigator.pop(context);
                            setState(() {
                              _isLogin = true;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Iconsax.call, size: 18, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'Đăng ký bằng SĐT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
