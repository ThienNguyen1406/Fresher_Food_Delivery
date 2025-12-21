import 'package:flutter/material.dart';
import 'package:fresher_food/models/User.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';

/// Widget màn hình đăng ký tài khoản mới
/// 
/// Màn hình này cho phép người dùng tạo tài khoản mới với các thông tin:
/// - Tên đăng nhập (username)
/// - Email
/// - Họ và tên
/// - Số điện thoại
/// - Địa chỉ
/// - Mật khẩu và xác nhận mật khẩu
/// 
/// Màn hình có hiệu ứng scroll animation cho logo và validation form đầy đủ
class RegisterScreen extends StatefulWidget {
  /// Vai trò của người dùng (chỉ cho phép 'user')
  final String role;
  
  /// Tên hiển thị của vai trò
  final String roleName;
  
  /// Màu chủ đạo cho giao diện
  final Color primaryColor;
  
  /// Callback khi người dùng muốn chuyển sang màn hình đăng nhập
  final VoidCallback? onSwitchToLogin;
  
  /// Callback khi đăng ký thành công
  final VoidCallback? onRegisterSuccess;
  
  /// Callback khi vai trò thay đổi (không sử dụng trong màn hình này)
  final Function(String role, String roleName, Color primaryColor)? onRoleChanged;

  const RegisterScreen({
    super.key,
    required this.role,
    required this.roleName,
    required this.primaryColor,
    this.onSwitchToLogin,
    this.onRegisterSuccess,
    this.onRoleChanged,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// State class quản lý trạng thái và logic của màn hình đăng ký
class _RegisterScreenState extends State<RegisterScreen> {
  /// Key để quản lý form validation
  final _formKey = GlobalKey<FormState>();
  
  /// Controller cho trường nhập tên đăng nhập
  final TextEditingController _usernameController = TextEditingController();
  
  /// Controller cho trường nhập email
  final TextEditingController _emailController = TextEditingController();
  
  /// Controller cho trường nhập mật khẩu
  final TextEditingController _passwordController = TextEditingController();
  
  /// Controller cho trường xác nhận mật khẩu
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  /// Controller cho trường nhập họ và tên
  final TextEditingController _fullNameController = TextEditingController();
  
  /// Controller cho trường nhập số điện thoại
  final TextEditingController _phoneController = TextEditingController();
  
  /// Controller cho trường nhập địa chỉ
  final TextEditingController _addressController = TextEditingController();
  
  /// Controller để quản lý scroll và animation logo
  final ScrollController _scrollController = ScrollController();

  /// Trạng thái đang xử lý đăng ký (hiển thị loading)
  bool _isLoading = false;
  
  /// Ẩn/hiện mật khẩu
  bool _obscurePassword = true;
  
  /// Ẩn/hiện mật khẩu xác nhận
  bool _obscureConfirmPassword = true;
  
  /// Chiều cao logo (tính theo tỷ lệ màn hình, mặc định 30%)
  double _logoHeight = 0.30;

  /// Khởi tạo state và đăng ký listener cho scroll controller
  @override
  void initState() {
    super.initState();
    // Đăng ký listener để theo dõi sự kiện scroll và cập nhật kích thước logo
    _scrollController.addListener(_onScroll);
  }

  /// Xử lý sự kiện scroll để tạo hiệu ứng animation cho logo
  /// 
  /// Khi người dùng scroll xuống, logo sẽ thu nhỏ dần từ 30% xuống 10% chiều cao màn hình
  /// để tạo không gian cho form đăng ký
  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    
    // Tính toán kích thước logo dựa trên scroll
    // Khi scroll = 0: logo = 30% màn hình
    // Khi scroll tăng: logo giảm dần xuống tối thiểu 10% màn hình
    final maxScrollForAnimation = 200.0; // Scroll 200px để logo nhỏ hết
    final scrollProgress = (currentScroll / maxScrollForAnimation).clamp(0.0, 1.0);
    final newHeight = 0.30 - (scrollProgress * 0.20); // Từ 30% xuống 10%
    
    // Chỉ cập nhật state nếu có thay đổi đáng kể (tránh rebuild không cần thiết)
    if ((_logoHeight - newHeight).abs() > 0.001) {
      setState(() {
        _logoHeight = newHeight;
      });
    }
  }

  /// Giải phóng tài nguyên khi widget bị hủy
  /// 
  /// Hủy đăng ký listener và dispose tất cả các controller để tránh memory leak
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Xây dựng giao diện màn hình đăng ký
  /// 
  /// Tạo form đăng ký với các trường nhập liệu và validation
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return NotificationListener<ScrollNotification>(
      // Lắng nghe sự kiện scroll để cập nhật animation logo
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          _onScroll();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: MediaQuery.of(context).size.height * 0.01,
          bottom: 0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo với animation dựa trên scroll - thu nhỏ khi scroll xuống
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  top: screenHeight * 0.01,
                  bottom: screenHeight * 0.01,
                ),
                child: Image.asset(
                  "lib/assets/img/loginImg.png",
                  height: screenHeight * _logoHeight,
                  fit: BoxFit.contain,
                ),
              ),

              // Tiêu đề chào mừng
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                'Tạo tài khoản mới',
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
                'Đăng ký để bắt đầu',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Trường nhập tên đăng nhập
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: localizations.username,
                hintText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: _usernameController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _usernameController.clear();
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              // Cập nhật UI khi text thay đổi (để hiển thị nút xóa)
              onChanged: (_) => setState(() {}),
              // Validation: kiểm tra tên đăng nhập không được để trống
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterUsername;
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường nhập email với validation định dạng email
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường nhập họ và tên
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: localizations.fullName,
                hintText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline, color: widget.primaryColor, size: 22),
                suffixIcon: _fullNameController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _fullNameController.clear();
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => setState(() {}),
              // Validation: kiểm tra họ và tên không được để trống
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterFullName;
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường nhập số điện thoại (không bắt buộc)
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: localizations.phone,
                hintText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _phoneController.clear();
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
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường nhập địa chỉ (không bắt buộc)
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: localizations.address,
                hintText: 'Địa chỉ',
                prefixIcon: Icon(Icons.location_on_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: _addressController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _addressController.clear();
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
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.streetAddressLine1],
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường nhập mật khẩu với nút ẩn/hiện mật khẩu
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: localizations.password,
                hintText: 'Tối thiểu 6 ký tự',
                prefixIcon: Icon(Icons.lock_outlined, color: widget.primaryColor, size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút xóa mật khẩu
                    if (_passwordController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _passwordController.clear();
                          });
                        },
                      ),
                    // Nút ẩn/hiện mật khẩu
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Trường xác nhận mật khẩu - phải khớp với mật khẩu đã nhập
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: localizations.confirmPassword,
                hintText: 'Nhập lại mật khẩu',
                prefixIcon: Icon(Icons.lock_outline, color: widget.primaryColor, size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_confirmPasswordController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordController.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              // Khi nhấn Enter trên trường này sẽ gọi hàm đăng ký
              onFieldSubmitted: (_) => _handleRegister(),
              // Validation: kiểm tra mật khẩu xác nhận phải khớp với mật khẩu
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseConfirmPassword;
                }
                if (value != _passwordController.text) {
                  return localizations.passwordMismatch;
                }
                return null;
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Nút đăng ký - xử lý việc tạo tài khoản mới
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                        localizations.register,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Link chuyển sang màn hình đăng nhập cho người dùng đã có tài khoản
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Đã có tài khoản? ',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: widget.onSwitchToLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Đăng nhập ngay',
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
    )
    );
  }

  /// Xử lý sự kiện đăng ký tài khoản
  /// 
  /// 1. Validate tất cả các trường trong form
  /// 2. Tạo đối tượng User với thông tin từ form
  /// 3. Gọi API đăng ký
  /// 4. Hiển thị thông báo kết quả
  /// 5. Xóa form và chuyển sang màn hình đăng nhập nếu thành công
  Future<void> _handleRegister() async {
    // Kiểm tra validation của form trước khi submit
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Tạo đối tượng User với thông tin từ form
        final user = User(
          maTaiKhoan: '', // Server sẽ tự động generate mã tài khoản
          tenNguoiDung: _usernameController.text.trim(),
          matKhau: _passwordController.text,
          email: _emailController.text.trim(),
          hoTen: _fullNameController.text.trim(),
          sdt: _phoneController.text.trim(),
          diaChi: _addressController.text.trim(),
          vaiTro: 'user', // Chỉ cho phép đăng ký với vai trò user (không cho phép đăng ký admin)
        );

        // Gọi API đăng ký
        final success = await UserApi().register(user);

        if (success) {
          final localizations = AppLocalizations.of(context)!;
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.registerSuccess),
              backgroundColor: Colors.green,
            ),
          );

          // Xóa tất cả các trường trong form sau khi đăng ký thành công
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _fullNameController.clear();
          _phoneController.clear();
          _addressController.clear();

          // Chuyển sang màn hình đăng nhập sau khi đăng ký thành công
          if (widget.onRegisterSuccess != null) {
            widget.onRegisterSuccess!();
          } else if (widget.onSwitchToLogin != null) {
            widget.onSwitchToLogin!();
          }
        }
      } catch (e) {
        // Xử lý lỗi và hiển thị thông báo lỗi
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.registerFailed}: $e'),
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
