import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';

/// Widget màn hình đăng nhập
/// 
/// Màn hình này cho phép người dùng đăng nhập vào hệ thống với:
/// - Chọn vai trò: Khách Hàng hoặc Admin (thông qua TabBar)
/// - Nhập email và mật khẩu
/// - Tùy chọn "Nhớ đăng nhập"
/// - Link chuyển sang màn hình đăng ký
class LoginScreen extends StatefulWidget {
  /// Vai trò hiện tại được chọn ('user' hoặc 'admin')
  final String role;
  
  /// Tên hiển thị của vai trò
  final String roleName;
  
  /// Màu chủ đạo cho giao diện
  final Color primaryColor;
  
  /// Callback khi người dùng muốn chuyển sang màn hình đăng ký
  final VoidCallback? onSwitchToRegister;
  
  /// Callback khi người dùng thay đổi vai trò (Admin/User)
  final Function(String role, String roleName, Color primaryColor)? onRoleChanged;

  const LoginScreen({
    super.key,
    required this.role,
    required this.roleName,
    required this.primaryColor,
    this.onSwitchToRegister,
    this.onRoleChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State class quản lý trạng thái và logic của màn hình đăng nhập
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  /// Key để quản lý form validation
  final _formKey = GlobalKey<FormState>();
  
  /// Controller cho trường nhập email
  final TextEditingController _emailController = TextEditingController();
  
  /// Controller cho trường nhập mật khẩu
  final TextEditingController _passwordController = TextEditingController();
  
  /// Controller để quản lý TabBar chọn vai trò (Khách Hàng/Admin)
  late TabController _roleTabController;

  /// Trạng thái đang xử lý đăng nhập (hiển thị loading)
  bool _isLoading = false;
  
  /// Ẩn/hiện mật khẩu
  bool _obscurePassword = true;
  
  /// Trạng thái checkbox "Nhớ đăng nhập"
  bool _rememberMe = false;

  /// Khởi tạo state và TabController cho việc chọn vai trò
  @override
  void initState() {
    super.initState();
    // Tạo TabController với 2 tab: Khách Hàng (index 0) và Admin (index 1)
    _roleTabController = TabController(
      length: 2,
      vsync: this,
      // Chọn tab ban đầu dựa trên role được truyền vào
      initialIndex: widget.role == 'user' ? 0 : 1,
    );
    // Đăng ký listener để theo dõi khi người dùng chuyển tab
    _roleTabController.addListener(_onRoleTabChanged);
  }

  /// Xử lý sự kiện khi người dùng chuyển đổi giữa tab Khách Hàng và Admin
  /// 
  /// Cập nhật role, roleName và primaryColor tương ứng với tab được chọn
  void _onRoleTabChanged() {
    // Bỏ qua nếu đang trong quá trình chuyển tab (tránh gọi callback nhiều lần)
    if (_roleTabController.indexIsChanging) return;
    final index = _roleTabController.index;
    if (index == 0) {
      // Tab Khách Hàng được chọn
      widget.onRoleChanged?.call('user', 'Khách Hàng', Colors.green);
    } else {
      // Tab Admin được chọn
      widget.onRoleChanged?.call('admin', 'Admin', Colors.blue);
    }
  }

  /// Cập nhật TabController khi role thay đổi từ bên ngoài
  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu role thay đổi, tự động chuyển sang tab tương ứng
    if (oldWidget.role != widget.role) {
      _roleTabController.animateTo(widget.role == 'user' ? 0 : 1);
    }
  }

  /// Giải phóng tài nguyên khi widget bị hủy
  @override
  void dispose() {
    _roleTabController.removeListener(_onRoleTabChanged);
    _roleTabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xây dựng giao diện màn hình đăng nhập
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).size.height * 0.01,
        bottom: 0, // Không có padding dưới để giảm khoảng trống
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề chào mừng
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              'Chào mừng bạn quay lại!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color ?? Colors.black87,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Mô tả phụ
            Text(
              'Đăng nhập để tiếp tục',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),

            // TabBar để chọn vai trò: Khách Hàng hoặc Admin
            Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.015),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _roleTabController,
                indicator: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Khách Hàng'),
                  Tab(text: 'Admin'),
                ],
              ),
            ),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: localizations.email,
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: _emailController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _emailController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => setState(() {}),
              // Validation: kiểm tra email không được để trống và phải có định dạng hợp lệ
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterEmail;
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return localizations.invalidEmail;
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),

            // Trường nhập mật khẩu với nút ẩn/hiện mật khẩu
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: localizations.password,
                hintText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_passwordController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _passwordController.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => setState(() {}),
              // Khi nhấn Enter trên trường này sẽ gọi hàm đăng nhập
              onFieldSubmitted: (_) => _handleLogin(),
              // Validation: kiểm tra mật khẩu không được để trống và tối thiểu 6 ký tự
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterPassword;
                }
                if (value.length < 6) {
                  return localizations.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Hàng chứa checkbox "Nhớ đăng nhập" và link "Quên mật khẩu"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Checkbox "Nhớ đăng nhập" - cho phép người dùng lưu thông tin đăng nhập
                InkWell(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: widget.primaryColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nhớ đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Link "Quên mật khẩu" - hiện tại chỉ hiển thị thông báo tính năng đang phát triển
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Tính năng quên mật khẩu đang được phát triển'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Nút đăng nhập - xử lý việc xác thực người dùng
            SizedBox(
              height: 56,
              child: ElevatedButton(
                // Vô hiệu hóa nút khi đang xử lý đăng nhập
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: widget.primaryColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        localizations.login,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Link chuyển sang màn hình đăng ký cho người dùng chưa có tài khoản
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chưa có tài khoản? ',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: widget.onSwitchToRegister,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Đăng ký ngay',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.primaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: widget.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Xử lý sự kiện đăng nhập
  /// 
  /// 1. Validate form (email và mật khẩu)
  /// 2. Gọi API đăng nhập với email và mật khẩu
  /// 3. Kiểm tra role của user có khớp với tab được chọn không
  /// 4. Chuyển hướng đến màn hình tương ứng:
  ///    - Admin -> Admin Dashboard
  ///    - User -> Main Screen (màn hình chính của người dùng)
  /// 5. Hiển thị thông báo lỗi nếu có
  Future<void> _handleLogin() async {
    // Kiểm tra validation của form trước khi submit
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Gọi API đăng nhập với email và mật khẩu
        final user = await UserApi().login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          // Kiểm tra role của user có khớp với tab được chọn không
          // Ví dụ: nếu chọn tab "Admin" nhưng tài khoản là "user" thì báo lỗi
          final userRole = user.vaiTro.toLowerCase();
          final expectedRole = widget.role.toLowerCase();

          if (userRole != expectedRole) {
            // Hiển thị thông báo lỗi và yêu cầu đăng nhập ở tab đúng
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tài khoản này không phải ${widget.roleName}. Vui lòng đăng nhập ở tab ${userRole == 'admin' ? 'Admin' : 'Khách Hàng'}.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // Phân quyền và chuyển hướng dựa trên vai trò của người dùng
          if (userRole == 'admin') {
            // Chuyển đến màn hình quản trị dành cho Admin
            AppRoute.toAdminDashboard(context);
          } else {
            // Chuyển đến màn hình chính dành cho User
            AppRoute.toMain(context);
          }
        }
      } catch (e) {
        // Xử lý lỗi và hiển thị thông báo lỗi
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.loginFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Tắt loading indicator
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
