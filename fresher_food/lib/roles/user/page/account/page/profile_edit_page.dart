import 'package:flutter/material.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fresher_food/utils/constant.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final UserApi _userApi = UserApi();
  
  late TextEditingController _tenNguoiDungController;
  late TextEditingController _hoTenController;
  late TextEditingController _emailController;
  late TextEditingController _sdtController;
  late TextEditingController _diaChiController;
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  String? _avatarPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tenNguoiDungController = TextEditingController();
    _hoTenController = TextEditingController();
    _emailController = TextEditingController();
    _sdtController = TextEditingController();
    _diaChiController = TextEditingController();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final userInfo = await _userApi.getUserInfo();
      setState(() {
        _tenNguoiDungController.text = userInfo['tenTaiKhoan'] ?? '';
        _hoTenController.text = userInfo['hoTen'] ?? '';
        _emailController.text = userInfo['email'] ?? '';
        _sdtController.text = userInfo['sdt'] ?? '';
        _diaChiController.text = userInfo['diaChi'] ?? '';
        _avatarPath = userInfo['avatar'];
        if (_avatarPath != null && _avatarPath!.isNotEmpty) {
          _avatarUrl = '${Constant().baseUrl.replaceAll('/api', '')}/$_avatarPath';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Lỗi tải thông tin: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userData = {
        'tenNguoiDung': _tenNguoiDungController.text.trim(),
        'hoTen': _hoTenController.text.trim(),
        'email': _emailController.text.trim(),
        'sdt': _sdtController.text.trim(),
        'diaChi': _diaChiController.text.trim(),
      };

      final success = await _userApi.updateUserInfo(userData);
      if (success) {
        _showSuccessSnackbar('Cập nhật thông tin thành công');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackbar('Cập nhật thất bại');
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final maTaiKhoan = prefs.getString('maTaiKhoan');
      if (maTaiKhoan == null) {
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      final result = await _userApi.uploadAvatar(maTaiKhoan, File(image.path));

      if (mounted) {
        if (result != null && result['success'] == true) {
          setState(() {
            _avatarPath = result['avatarPath'];
            _avatarUrl = result['avatarUrl'];
            _isUploadingAvatar = false;
          });
          _showSuccessSnackbar('Cập nhật ảnh đại diện thành công');
        } else {
          setState(() {
            _isUploadingAvatar = false;
          });
          _showErrorSnackbar(result?['error'] ?? 'Upload avatar thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      // Gọi API xóa avatar (method tự động lấy user hiện tại)
      final success = await _userApi.deleteAvatar();
      
      if (mounted) {
        if (success) {
          setState(() {
            _avatarPath = null;
            _avatarUrl = null;
          });
          _showSuccessSnackbar('Đã xóa ảnh đại diện');
        } else {
          _showErrorSnackbar('Xóa ảnh đại diện thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Lỗi: $e');
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ChangePasswordDialog(
        onSuccess: (message) {
          Navigator.pop(dialogContext);
          _showSuccessSnackbar(message);
        },
        onError: (error) {
          Navigator.pop(dialogContext);
          _showErrorSnackbar(error);
        },
        onCancel: () {
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tenNguoiDungController.dispose();
    _hoTenController.dispose();
    _emailController.dispose();
    _sdtController.dispose();
    _diaChiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Ảnh đại diện',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667EEA),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: _isUploadingAvatar
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                    onPressed: _isUploadingAvatar
                                        ? null
                                        : _pickAndUploadAvatar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isUploadingAvatar || _avatarPath == null
                                ? null
                                : _removeAvatar,
                            child: const Text(
                              'Xóa ảnh đại diện',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _tenNguoiDungController,
                            label: 'Tên đăng nhập',
                            icon: Icons.person_outline,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _hoTenController,
                            label: 'Họ và tên *',
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email *',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _sdtController,
                            label: 'Số điện thoại',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _diaChiController,
                            label: 'Địa chỉ',
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nút đổi mật khẩu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.key,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Thay đổi mật khẩu tài khoản của bạn',
                          style: TextStyle(fontSize: 13),
                        ),
                        trailing: const Icon(Iconsax.arrow_right_3),
                        onTap: () => _showChangePasswordDialog(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Lưu thông tin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enableInteractiveSelection: true,
      enableSuggestions: true,
      autocorrect: true,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }
}

// Widget riêng để quản lý dialog đổi mật khẩu
class _ChangePasswordDialog extends StatefulWidget {
  final Function(String) onSuccess;
  final Function(String) onError;
  final VoidCallback onCancel;

  const _ChangePasswordDialog({
    required this.onSuccess,
    required this.onError,
    required this.onCancel,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _userApi = UserApi();
  
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChanging = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isChanging = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maTaiKhoan = prefs.getString('maTaiKhoan');
      if (maTaiKhoan == null) {
        throw Exception('Không tìm thấy thông tin tài khoản');
      }

      final result = await _userApi.changePassword(
        maTaiKhoan: maTaiKhoan,
        matKhauCu: _oldPasswordController.text,
        matKhauMoi: _newPasswordController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          widget.onSuccess(result['message'] ?? 'Đổi mật khẩu thành công');
        } else {
          widget.onError(result['error'] ?? 'Đổi mật khẩu thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onError('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChanging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.key,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: const Icon(Iconsax.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword ? Iconsax.eye_slash : Iconsax.eye,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu cũ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Iconsax.lock_1),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Iconsax.eye_slash : Iconsax.eye,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Iconsax.lock_1),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isChanging ? null : widget.onCancel,
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isChanging ? null : _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isChanging
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Đổi mật khẩu'),
        ),
      ],
    );
  }
}

