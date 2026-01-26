import 'package:flutter/material.dart';
import 'package:fresher_food/services/api/user_api.dart';

class ChiTietNguoiDungScreen extends StatefulWidget {
  final Map<String, dynamic> nguoiDung;
  final UserApi api;

  const ChiTietNguoiDungScreen({super.key, required this.nguoiDung, required this.api});

  @override
  State<ChiTietNguoiDungScreen> createState() => _ChiTietNguoiDungScreenState();
}

class _ChiTietNguoiDungScreenState extends State<ChiTietNguoiDungScreen> {
  late TextEditingController _tenNguoiDungCtrl;
  late TextEditingController _hoTenCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _sdtCtrl;
  late TextEditingController _diaChiCtrl;

  String _vaiTro = 'User';
  bool _dangLuu = false;

  final List<String> _vaiTroHople = ['User', 'Admin'];

  // Màu sắc chủ đạo
  final Color _primaryColor = Color(0xFF10B981);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF1E293B);
  final Color _secondaryTextColor = Color(0xFF64748B);
  final Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    final nd = widget.nguoiDung;
    _tenNguoiDungCtrl = TextEditingController(text: nd['tenNguoiDung'] ?? '');
    _hoTenCtrl = TextEditingController(text: nd['hoTen'] ?? '');
    _emailCtrl = TextEditingController(text: nd['email'] ?? '');
    _sdtCtrl = TextEditingController(text: nd['sdt'] ?? '');
    _diaChiCtrl = TextEditingController(text: nd['diaChi'] ?? '');

    // ⚡ Fix dropdown value
    final vaiTroBanDau = nd['vaiTro']?.toString() ?? '';
    _vaiTro = _vaiTroHople.firstWhere(
      (v) => v.toLowerCase() == vaiTroBanDau.toLowerCase(),
      orElse: () => 'User',
    );
  }

  @override
  void dispose() {
    _tenNguoiDungCtrl.dispose();
    _hoTenCtrl.dispose();
    _emailCtrl.dispose();
    _sdtCtrl.dispose();
    _diaChiCtrl.dispose();
    super.dispose();
  }

  Future<void> _capNhatNguoiDung() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();
    
    setState(() => _dangLuu = true);

    final data = {
      "MaTaiKhoan": widget.nguoiDung['maTaiKhoan'] ?? '',
      "TenNguoiDung": _tenNguoiDungCtrl.text.trim(),
      "MatKhau": "", // Empty string - backend sẽ giữ nguyên mật khẩu cũ
      "HoTen": _hoTenCtrl.text.trim(),
      "Email": _emailCtrl.text.trim(),
      "Sdt": _sdtCtrl.text.trim(),
      "DiaChi": _diaChiCtrl.text.trim(),
      "VaiTro": _vaiTro,
    };

    try {
      print('🔄 Đang cập nhật thông tin người dùng: ${widget.nguoiDung['maTaiKhoan']}');
      print('📝 Dữ liệu: $data');
      
      final thanhCong =
          await widget.api.updateNguoiDung(widget.nguoiDung['maTaiKhoan'], data);
      
      if (thanhCong) {
        print('✅ Cập nhật thông tin thành công');
        _showSnackbar('Cập nhật thông tin thành công!', true);
        Navigator.pop(context, true);
      } else {
        print('❌ Cập nhật thất bại - API trả về false');
        _showSnackbar('Cập nhật thất bại. Vui lòng thử lại.', false);
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật thông tin: $e');
      _showSnackbar('Lỗi: ${e.toString()}', false);
    } finally {
      setState(() => _dangLuu = false);
    }
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              enableInteractiveSelection: !readOnly,
              enableSuggestions: !readOnly && keyboardType == TextInputType.text,
              autocorrect: !readOnly && keyboardType == TextInputType.text,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: _cardColor,
                prefixIcon: Icon(icon, color: _secondaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vai trò',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _vaiTro,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: _secondaryTextColor),
                  style: TextStyle(
                    fontSize: 16,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _vaiTroHople.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            role == 'Admin' ? Icons.admin_panel_settings : Icons.person,
                            color: role == 'Admin' ? Colors.orange : _primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(role),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _vaiTro = value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar và thông tin cơ bản
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.1), _primaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nguoiDung['hoTen'] ?? 'Chưa có tên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.nguoiDung['tenNguoiDung'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _vaiTro == 'Admin' ? Colors.orange.withOpacity(0.1) : _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _vaiTro,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _vaiTro == 'Admin' ? Colors.orange : _primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Form thông tin
          _buildTextField(
            controller: _tenNguoiDungCtrl,
            label: 'Tên đăng nhập',
            icon: Icons.person_outline,
          ),
          _buildTextField(
            controller: _hoTenCtrl,
            label: 'Họ và tên',
            icon: Icons.badge_outlined,
          ),
          _buildTextField(
            controller: _sdtCtrl,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _buildTextField(
            controller: _diaChiCtrl,
            label: 'Địa chỉ',
            icon: Icons.location_on_outlined,
          ),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildRoleSelector(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chi tiết người dùng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID: ${widget.nguoiDung['maTaiKhoan'] ?? ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              _buildUserInfoCard(),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _dangLuu ? null : _capNhatNguoiDung,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _dangLuu
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}