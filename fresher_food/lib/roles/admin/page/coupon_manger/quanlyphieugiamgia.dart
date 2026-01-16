import 'package:flutter/material.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:provider/provider.dart';

/// Màn hình quản lý phiếu giảm giá - xem, tìm kiếm và xóa mã giảm giá
class QuanLyPhieuGiamGiaScreen extends StatefulWidget {
  const QuanLyPhieuGiamGiaScreen({super.key});

  @override
  State<QuanLyPhieuGiamGiaScreen> createState() => _QuanLyPhieuGiamGiaScreenState();
}

class _QuanLyPhieuGiamGiaScreenState extends State<QuanLyPhieuGiamGiaScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PhieuGiamGia> _coupons = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Color palette chuyên nghiệp
  final Color _primaryColor = Color(0xFF10B981);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF0F172A);
  final Color _textSecondary = Color(0xFF64748B);
  final Color _textTertiary = Color(0xFF94A3B8);
  final Color _borderColor = Color(0xFFE2E8F0);
  final Color _successColor = Color(0xFF10B981);
  final Color _warningColor = Color(0xFFF59E0B);
  final Color _errorColor = Color(0xFFEF4444);

  // Gradient colors for different voucher types
  final Map<String, List<Color>> _voucherGradients = {
    'percent': [Color(0xFF667EEA), Color(0xFF764BA2)],
    'small': [Color(0xFF10B981), Color(0xFF059669)],
    'medium': [Color(0xFFF59E0B), Color(0xFFD97706)],
    'large': [Color(0xFFEF4444), Color(0xFFDC2626)],
  };

  /// Khối khởi tạo: Load danh sách phiếu giảm giá từ server
  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Khối chức năng: Load tất cả phiếu giảm giá từ API
  Future<void> _loadCoupons() async {
    try {
      setState(() => _isLoading = true);
      final apiService = Provider.of<CouponApi>(context, listen: false);
      _coupons = await apiService.getAllCoupons();
    } catch (e) {
      _showSnackbar('Lỗi tải dữ liệu: $e', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Khối chức năng: Lọc phiếu giảm giá theo từ khóa tìm kiếm
  void _filterCoupons() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  /// Khối chức năng: Lấy danh sách phiếu giảm giá đã lọc theo mã hoặc mô tả
  List<PhieuGiamGia> get _filteredCoupons {
    if (_searchQuery.isEmpty) return _coupons;
    return _coupons.where((coupon) =>
      coupon.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      coupon.moTa.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  /// Khối chức năng: Xóa phiếu giảm giá với dialog xác nhận
  Future<void> _deleteCoupon(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận xóa', 
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
        content: Text('Bạn có chắc muốn xóa phiếu giảm giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = Provider.of<CouponApi>(context, listen: false);
      final success = await apiService.deleteCoupon(id);
      
      if (success) {
        _showSnackbar('Xóa thành công', true);
        _loadCoupons();
      } else {
        _showSnackbar('Xóa thất bại', false);
      }
    } catch (e) {
      _showSnackbar('Lỗi: $e', false);
    }
  }

  void _showAddEditDialog({PhieuGiamGia? coupon}) {
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final valueCtrl = TextEditingController(text: coupon?.giaTri.toString() ?? '');
    final descCtrl = TextEditingController(text: coupon?.moTa ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.all(20),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _surfaceColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    coupon == null ? 'Thêm mã giảm giá' : 'Chỉnh sửa mã giảm giá',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: _textPrimary
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textTertiary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildTextField(
                controller: codeCtrl,
                label: 'Mã giảm giá',
                icon: Icons.local_offer_outlined,
                hintText: 'Nhập mã giảm giá...',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: valueCtrl,
                label: 'Giá trị',
                icon: Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
                hintText: 'Nhập giá trị...',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: descCtrl,
                label: 'Mô tả',
                icon: Icons.description_outlined,
                maxLines: 2,
                hintText: 'Nhập mô tả...',
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _borderColor),
                      ),
                      child: Text('Hủy', 
                          style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (codeCtrl.text.isEmpty || valueCtrl.text.isEmpty) {
                          _showSnackbar('Vui lòng nhập đầy đủ thông tin', false);
                          return;
                        }

                        final giaTri = double.tryParse(valueCtrl.text);
                        if (giaTri == null) {
                          _showSnackbar('Giá trị không hợp lệ', false);
                          return;
                        }

                        final newCoupon = PhieuGiamGia(
                          idPhieuGiamGia: coupon?.idPhieuGiamGia ?? '',
                          code: codeCtrl.text.trim(),
                          giaTri: giaTri,
                          moTa: descCtrl.text.trim(),
                        );

                        try {
                          final apiService = Provider.of<CouponApi>(context, listen: false);
                          String result;
                          
                          if (coupon == null) {
                            result = await apiService.createCoupon(newCoupon);
                          } else {
                            result = await apiService.updateCoupon(coupon.idPhieuGiamGia, newCoupon);
                          }

                          _showSnackbar(result, true);
                          _loadCoupons();
                          Navigator.pop(context);
                        } catch (e) {
                          _showSnackbar('Lỗi: $e', false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Lưu', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
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
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          maxLines: maxLines,
          enableInteractiveSelection: true,
          enableSuggestions: keyboardType == TextInputType.text && maxLines == 1,
          autocorrect: keyboardType == TextInputType.text && maxLines == 1,
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: _textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            filled: true,
            fillColor: _backgroundColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _successColor : _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String _getVoucherType(double giaTri) {
    if (giaTri <= 100) return 'percent';
    if (giaTri >= 100000) return 'large';
    if (giaTri >= 50000) return 'medium';
    return 'small';
  }

  String _getDiscountText(PhieuGiamGia voucher) {
    return voucher.giaTri <= 100 
        ? '${voucher.giaTri}%' 
        : '${_formatCurrency(voucher.giaTri)}₫';
  }

  String _formatCurrency(double value) {
    String stringValue = value.toInt().toString();
    String reversed = stringValue.split('').reversed.join('');
    String formatted = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }
    
    return formatted.split('').reversed.join('');
  }

  String _getVoucherSubtitle(double giaTri) {
    if (giaTri <= 100) return 'Giảm theo phần trăm';
    if (giaTri >= 100000) return 'Ưu đãi đặc biệt';
    if (giaTri >= 50000) return 'Ưu đãi lớn';
    return 'Ưu đãi tiền mặt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: _primaryColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Chỉ giữ lại thanh tìm kiếm
          Container(
            padding: EdgeInsets.fromLTRB(24, 56, 24, 24),
            color: _surfaceColor,
            child: Container(
              decoration: BoxDecoration(
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
                controller: _searchController,
                onChanged: (_) => _filterCoupons(),
                enableInteractiveSelection: true,
                enableSuggestions: true,
                autocorrect: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mã giảm giá...',
                  prefixIcon: Icon(Icons.search, color: _textTertiary),
                  filled: true,
                  fillColor: _backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredCoupons.isEmpty
                    ? _buildEmptyState()
                    : _buildVoucherList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Đang tải phiếu giảm giá...',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard,
              size: 60,
              color: _textTertiary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty 
                ? 'Chưa có mã giảm giá'
                : 'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tạo mã giảm giá đầu tiên của bạn'
                : 'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddEditDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Thêm mã giảm giá',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: _filteredCoupons.length,
      itemBuilder: (context, index) {
        final voucher = _filteredCoupons[index];
        return _buildVoucherCard(voucher);
      },
    );
  }

  Widget _buildVoucherCard(PhieuGiamGia voucher) {
    final voucherType = _getVoucherType(voucher.giaTri);
    final gradientColors = _voucherGradients[voucherType]!;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Column(
                children: [
                  // Voucher content
                  Container(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Discount value
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getDiscountText(voucher),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voucher.code,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                _getVoucherSubtitle(voucher.giaTri),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (voucher.moTa.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  voucher.moTa,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradientColors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            voucher.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: gradientColors[0],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              color: _warningColor,
                              onPressed: () => _showAddEditDialog(coupon: voucher),
                              tooltip: 'Chỉnh sửa',
                            ),
                            SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.delete_outlined,
                              color: _errorColor,
                              onPressed: () => _deleteCoupon(voucher.idPhieuGiamGia),
                              tooltip: 'Xóa',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(icon, size: 18, color: color),
          onPressed: onPressed,
          padding: EdgeInsets.all(10),
          constraints: BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }
}