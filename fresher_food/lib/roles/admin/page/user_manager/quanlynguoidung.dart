import 'package:flutter/material.dart';
import 'package:fresher_food/roles/admin/page/user_manager/chitietnguoidung.dart';
import 'package:fresher_food/roles/admin/page/user_manager/password_reset_requests_page.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:iconsax/iconsax.dart';

/// Màn hình quản lý người dùng - xem, tìm kiếm và xóa tài khoản người dùng
class QuanLyNguoiDungScreen extends StatefulWidget {
  const QuanLyNguoiDungScreen({super.key});

  @override
  State<QuanLyNguoiDungScreen> createState() => _QuanLyNguoiDungScreenState();
}

class _QuanLyNguoiDungScreenState extends State<QuanLyNguoiDungScreen> {
  final api = UserApi();
  List<dynamic> _tatCaNguoiDung = [];
  List<dynamic> _nguoiDungHienThi = [];
  String _tuKhoa = '';
  bool _dangTai = false;

  // Màu sắc chủ đạo
  final Color _primaryColor = Color(0xFF10B981);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF1E293B);
  final Color _secondaryTextColor = Color(0xFF64748B);
  final Color borderColor = Color(0xFFE2E8F0);

  /// Khối khởi tạo: Load danh sách người dùng từ server
  @override
  void initState() {
    super.initState();
    _taiNguoiDung();
  }

  /// Khối chức năng: Load tất cả người dùng từ API
  Future<void> _taiNguoiDung() async {
    setState(() => _dangTai = true);
    try {
      final data = await api.getUsers();
      _tatCaNguoiDung = data;
      _locNguoiDung();
    } catch (e) {
      _showSnackbar('Lỗi tải dữ liệu: $e', false);
    } finally {
      setState(() => _dangTai = false);
    }
  }

  /// Khối chức năng: Lọc người dùng theo từ khóa (tên đăng nhập, họ tên, email)
  void _locNguoiDung() {
    setState(() {
      _nguoiDungHienThi = _tatCaNguoiDung.where((nd) {
        final tenDangNhap = nd['tenNguoiDung'] ?? '';
        final hoTen = nd['hoTen'] ?? '';
        final email = nd['email'] ?? '';
        return tenDangNhap.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
            hoTen.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
            email.toLowerCase().contains(_tuKhoa.toLowerCase());
      }).toList();
    });
  }

  /// Khối chức năng: Lấy màu hiển thị theo vai trò (admin/user)
  Color _mauVaiTro(String vaiTro) {
    return vaiTro.toLowerCase() == 'admin' ? Color(0xFFFF6B6B) : _primaryColor;
  }

  IconData _iconVaiTro(String vaiTro) {
    return vaiTro.toLowerCase() == 'admin' ? Icons.admin_panel_settings : Icons.person;
  }

  /// Khối chức năng: Xóa người dùng với dialog xác nhận
  Future<void> _xoaNguoiDung(Map<String, dynamic> nd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
        ),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản "${nd['tenNguoiDung']}" không?',
          style: TextStyle(color: _secondaryTextColor),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _secondaryTextColor,
            ),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🔄 Đang xóa tài khoản: ${nd['maTaiKhoan']}');
        final thanhCong = await api.deleteNguoiDung(nd['maTaiKhoan']);
        if (thanhCong) {
          print('✅ Xóa tài khoản thành công');
          _showSnackbar('Xóa tài khoản thành công!', true);
          // Reload danh sách sau khi xóa thành công
          await _taiNguoiDung();
        } else {
          print('❌ Xóa tài khoản thất bại - API trả về false');
          _showSnackbar('Xóa tài khoản thất bại. Vui lòng thử lại hoặc kiểm tra dữ liệu liên quan.', false);
        }
      } catch (e) {
        print('❌ Lỗi khi xóa tài khoản: $e');
        final errorMsg = e.toString().contains('REFERENCE constraint') 
            ? 'Không thể xóa người dùng vì còn dữ liệu liên quan. Vui lòng xóa các đơn hàng, giỏ hàng và chat trước.'
            : 'Lỗi: ${e.toString()}';
        _showSnackbar(errorMsg, false);
      }
    }
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> nd) {
    final vaiTro = nd['vaiTro'] ?? 'User';
    final color = _mauVaiTro(vaiTro);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final ketQua = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChiTietNguoiDungScreen(
                  nguoiDung: nd,
                  api: api,
                ),
              ),
            );
            if (ketQua == true) _taiNguoiDung();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconVaiTro(vaiTro),
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                
                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nd['hoTen'] ?? 'Chưa có tên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        nd['email'] ?? 'Chưa có email',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vaiTro,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Username và action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      nd['tenNguoiDung'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        // Nút chỉnh sửa
                        Container(
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit_outlined, size: 18, color: _primaryColor),
                            onPressed: () async {
                              final ketQua = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChiTietNguoiDungScreen(
                                    nguoiDung: nd,
                                    api: api,
                                  ),
                                ),
                              );
                              if (ketQua == true) _taiNguoiDung();
                            },
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Nút xóa
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_outlined, size: 18, color: Colors.red),
                            onPressed: () => _xoaNguoiDung(nd),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        enableInteractiveSelection: true,
        enableSuggestions: true,
        autocorrect: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên, email hoặc username...',
          hintStyle: TextStyle(color: _secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onChanged: (value) {
          _tuKhoa = value;
          _locNguoiDung();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            _tuKhoa.isEmpty ? 'Chưa có người dùng nào' : 'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_tuKhoa.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(color: _secondaryTextColor),
            ),
          ],
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
          'Quản lý người dùng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontSize: 20,
          ),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.key,
              color: _textColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordResetRequestsPage(),
                ),
              );
            },
            tooltip: 'Yêu cầu đặt lại mật khẩu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Thống kê
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tổng số: ${_nguoiDungHienThi.length} người dùng',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                if (_dangTai)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Danh sách người dùng
          Expanded(
            child: _dangTai && _nguoiDungHienThi.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải dữ liệu...',
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _taiNguoiDung,
                    color: _primaryColor,
                    child: _nguoiDungHienThi.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _nguoiDungHienThi.length,
                            itemBuilder: (context, index) {
                              final nd = _nguoiDungHienThi[index];
                              return _buildUserCard(nd);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}