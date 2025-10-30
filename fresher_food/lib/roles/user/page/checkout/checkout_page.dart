import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/models/Pay.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/payment_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> selectedItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _paymentMethod = 'cod';
  String _selectedPaymentId = '';
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  Map<String, dynamic>? currentUserInfo;

  // New state variables for payment methods and coupons
  List<Pay> _paymentMethods = [];
  List<PhieuGiamGia> _availableCoupons = [];
  PhieuGiamGia? _selectedCoupon;
  double _discountAmount = 0.0;
  double _finalAmount = 0.0;
  double _shippingFee = 25000;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _secondaryColor = const Color(0xFF059669);
  final Color _accentColor = const Color(0xFF8B5CF6);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPaymentMethods();
    _loadAvailableCoupons();
    _finalAmount = widget.totalAmount + _shippingFee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildSimpleSuccessScreen() {
    return StatefulBuilder(
      builder: (context, setState) {
        int countdown = 5; // Giảm thời gian chờ xuống 5 giây
        Timer? timer;

        void startCountdown() {
          timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (countdown > 0) {
              setState(() {
                countdown--;
              });
            } else {
              timer.cancel();
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }

        // Bắt đầu đếm ngược khi widget được build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          startCountdown();
        });

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon thành công
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 32),

              // Tiêu đề
              Text(
                'Thanh toán thành công!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Mô tả
              Text(
                'Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi.\nĐơn hàng đang được xử lý và sẽ được giao sớm nhất.',
                style: TextStyle(
                  fontSize: 16,
                  color: _textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Đếm ngược
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tự động chuyển sau $countdown giây',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nút hành động
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: _primaryColor.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Về trang chủ ngay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserApi().getUserInfo();
      setState(() {
        currentUserInfo = userInfo;
        _nameController.text = userInfo['hoTen'] ?? '';
        _phoneController.text = userInfo['sdt'] ?? '';
        _addressController.text = userInfo['diaChi'] ?? '';
      });
    } catch (e) {
      print('Error loading user info: $e');
      _showErrorSnackBar('Lỗi tải thông tin người dùng: $e');
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final paymentMethods = await PaymentApi().getPay();
      setState(() {
        _paymentMethods = paymentMethods;
        // Set default payment method (COD)
        if (_paymentMethods.isNotEmpty) {
          final codMethod = _paymentMethods.firstWhere(
                (pay) => pay.Pay_name.toLowerCase().contains('cod'),
            orElse: () => _paymentMethods.first,
          );
          _selectedPaymentId = codMethod.Id_Pay;
          _paymentMethod = codMethod.Pay_name.toLowerCase().contains('cod') ? 'cod' : 'banking';
        }
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      _showErrorSnackBar('Lỗi tải phương thức thanh toán: $e');
    }
  }

  Future<void> _loadAvailableCoupons() async {
    try {
      final coupons = await CouponApi().getAllCoupons();
      setState(() {
        _availableCoupons = coupons;
      });
    } catch (e) {
      print('Error loading coupons: $e');
    }
  }

  void _updateFinalAmount() {
    setState(() {
      _finalAmount = (widget.totalAmount - _discountAmount + _shippingFee).clamp(0, double.infinity);
    });
  }

  void _showCouponSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        color: _primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chọn mã giảm giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _availableCoupons.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: _textSecondary.withOpacity(0.5),
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có mã giảm giá nào',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableCoupons.length,
                    itemBuilder: (context, index) {
                      final coupon = _availableCoupons[index];
                      final isSelected = _selectedCoupon?.idPhieuGiamGia == coupon.idPhieuGiamGia;

                      return _buildCouponItem(coupon, isSelected);
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                          ),
                          child: const Text('HỦY'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('XONG'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponItem(PhieuGiamGia coupon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCoupon = isSelected ? null : coupon;
            _discountAmount = isSelected ? 0.0 : coupon.giaTri;
            _updateFinalAmount();
          });
          if (!isSelected) {
            _showSuccessSnackBar('Đã áp dụng mã giảm giá ${coupon.code}');
          }
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor.withOpacity(0.1) : _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.discount_outlined,
                  color: isSelected ? Colors.white : _textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _primaryColor : _textPrimary,
                      ),
                    ),
                    if (coupon.moTa.isNotEmpty)
                      Text(
                        coupon.moTa,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _primaryColor.withOpacity(0.8) : _textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Giảm ${_formatPrice(coupon.giaTri)}đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isSelected ? _primaryColor : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _selectedCoupon = null;
      _discountAmount = 0.0;
      _updateFinalAmount();
    });
    _showSuccessSnackBar('Đã xóa mã giảm giá');
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.'
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Vui lòng kiểm tra lại thông tin');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin giao hàng');
      return;
    }

    // Kiểm tra số lượng tồn kho
    for (var item in widget.selectedItems) {
      if (item.soLuong > item.soLuongTon) {
        _showStockErrorDialog(item);
        return;
      }
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      await _navigateToPaymentScreen();
    } catch (e) {
      print('Error in payment process: $e');
      _showErrorSnackBar('Lỗi trong quá trình thanh toán: $e');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _navigateToPaymentScreen() async {
    // Xử lý theo phương thức thanh toán
    if (_paymentMethod == 'cod') {
      await _processCODPayment();
    } else if (_paymentMethod == 'momo' || _paymentMethod == 'banking') {
      await _processMoMoPayment();
    } else {
      _showErrorSnackBar('Phương thức thanh toán không được hỗ trợ');
    }
  }

  Future<void> _processCODPayment() async {
    _showProcessingDialog('Đang xử lý đơn hàng...');

    try {
      final success = await _createOrderAndClearCart('cod');

      Navigator.of(context).pop(); // Đóng dialog loading

      if (success) {
        _showSuccessScreen();
      } else {
        _showErrorSnackBar('Không thể tạo đơn hàng');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng dialog loading
      _showErrorSnackBar('Lỗi khi xử lý thanh toán COD: $e');
    }
  }

  Future<void> _processMoMoPayment() async {
    _showProcessingDialog('Đang chuyển hướng đến MoMo...');

    // Giả lập quá trình thanh toán MoMo
    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context).pop(); // Đóng dialog loading

    try {
      final success = await _createOrderAndClearCart('momo');

      if (success) {
        _showSuccessScreen();
      } else {
        _showErrorSnackBar('Không thể tạo đơn hàng sau thanh toán MoMo');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xử lý thanh toán MoMo: $e');
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _createOrderAndClearCart(String paymentMethod) async {
    try {
      final userInfo = await UserApi().getUserInfo();
      final maTaiKhoan = userInfo['maTaiKhoan'];

      if (maTaiKhoan == null || maTaiKhoan.isEmpty) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Tạo đơn hàng
      final order = Order(
        maDonHang: '',
        maTaiKhoan: maTaiKhoan,
        ngayDat: DateTime.now(),
        trangThai: 'pending',
        diaChiGiaoHang: _addressController.text.trim(),
        soDienThoai: _phoneController.text.trim(),
        ghiChu: _noteController.text.trim(),
        phuongThucThanhToan: paymentMethod,
        trangThaiThanhToan: paymentMethod == 'cod' ? 'pending' : 'paid',
        id_PhieuGiamGia: _selectedCoupon?.idPhieuGiamGia ?? '',
        id_Pay: _selectedPaymentId,
        // tongTien: _finalAmount,
        // phiVanChuyen: _shippingFee,
        // tongTienSauGiamGia: _finalAmount - _shippingFee,
      );

      final orderDetails = widget.selectedItems.map((item) {
        return OrderDetail(
          maDonHang: '',
          maSanPham: item.maSanPham,
          tenSanPham: item.tenSanPham,
          giaBan: item.giaBan,
          soLuong: item.soLuong,
          // thanhTien: item.thanhTien,
          // anh: item.anh,
        );
      }).toList();

      print('🔄 Đang tạo đơn hàng...');
      final orderSuccess = await OrderApi().createOrder(order, orderDetails);

      if (!orderSuccess) {
        throw Exception('Không thể tạo đơn hàng');
      }

      print('✅ Đơn hàng đã được tạo thành công');

      // Clear cart sau khi tạo đơn hàng thành công
      print('🔄 Đang xóa giỏ hàng...');
      try {
        await CartApi().clearCart();
        print('✅ Đã clear giỏ hàng thành công');
        return true;
      } catch (e) {
        print('⚠️ Lỗi khi clear giỏ hàng: $e');
        // Vẫn trả về true vì đơn hàng đã được tạo thành công
        return true;
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text('Thanh toán thành công'),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: _buildSimpleSuccessScreen(),
        ),
      ),
    );
  }

  void _showStockErrorDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Số lượng không đủ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sản phẩm "${item.tenSanPham}" chỉ còn ${item.soLuongTon} sản phẩm trong kho. Bạn đã chọn ${item.soLuong} sản phẩm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Quay lại giỏ hàng
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('QUAY LẠI GIỎ HÀNG'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade300,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: _primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Thanh toán',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _textPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: (_isLoading || _isProcessingPayment)
          ? _buildLoadingScreen()
          : _buildCheckoutContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang xử lý đơn hàng...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng không thoát ứng dụng',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // [_buildCheckoutContent, _buildSectionHeader, _buildDeliveryInfoCard,
  // _buildInfoRow, _buildNoteCard, _buildCouponSection, _buildPaymentMethod,
  // _buildPaymentOption, _buildSelectedProducts, _buildTotalSection,
  // _buildDivider, _buildTotalRow]

  Widget _buildCheckoutContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Thông tin giao hàng', Icons.local_shipping_outlined),
            _buildDeliveryInfoCard(),

            const SizedBox(height: 28),

            _buildSectionHeader('Ghi chú đơn hàng', Icons.note_add_outlined),
            _buildNoteCard(),

            const SizedBox(height: 28),

            _buildSectionHeader('Mã giảm giá', Icons.discount_outlined),
            _buildCouponSection(),

            const SizedBox(height: 28),

            _buildSectionHeader('Phương thức thanh toán', Icons.payment_outlined),
            _buildPaymentMethod(),

            const SizedBox(height: 28),

            _buildSectionHeader('Sản phẩm đã chọn', Icons.shopping_bag_outlined),
            _buildSelectedProducts(),

            const SizedBox(height: 28),

            _buildTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhận hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.person_outline, 'Họ và tên', _nameController.text),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_iphone_outlined, 'Số điện thoại', _phoneController.text),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', _addressController.text),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _textSecondary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'Chưa có thông tin',
                style: TextStyle(
                  fontSize: 14,
                  color: value.isNotEmpty ? _textPrimary : _textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cho đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(color: _textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Giao hàng giờ hành chính, gọi điện trước khi giao...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã giảm giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedCoupon == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCouponSelectionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _backgroundColor,
                  foregroundColor: _textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.discount_outlined, color: _primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.discount_outlined, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCoupon!.code,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        if (_selectedCoupon?.moTa != null && _selectedCoupon!.moTa.isNotEmpty)
                          Text(
                            _selectedCoupon!.moTa,
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        Text(
                          'Giảm ${_formatPrice(_selectedCoupon!.giaTri)}đ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeCoupon,
                    icon: Icon(Icons.close, color: _textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    if (_paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _paymentMethods.map((pay) {
          final isSelected = _selectedPaymentId == pay.Id_Pay;
          final payName = pay.Pay_name.toLowerCase();
          final isCOD = payName.contains('cod');
          final isMoMo = payName.contains('momo');

          IconData icon;
          Color color;
          String subtitle;

          if (isCOD) {
            icon = Icons.money_outlined;
            color = _primaryColor;
            subtitle = 'Thanh toán bằng tiền mặt khi nhận hàng';
          } else if (isMoMo) {
            icon = Icons.phone_iphone_outlined;
            color = Colors.pink;
            subtitle = 'Thanh toán qua ứng dụng MoMo';
          } else {
            icon = Icons.account_balance_outlined;
            color = _accentColor;
            // SỬA LỖI Ở ĐÂY: Kiểm tra nếu pay.Pay_name là null hoặc rỗng
            subtitle = pay.Pay_name != null && pay.Pay_name.isNotEmpty
                ? 'Thanh toán qua ${pay.Pay_name}'
                : 'Thanh toán trực tuyến';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentOption(
              value: pay.Id_Pay,
              title: pay.Pay_name.isNotEmpty ? pay.Pay_name : 'Thanh toán trực tuyến',
              subtitle: subtitle,
              icon: icon,
              color: color,
              isSelected: isSelected,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentId,
        onChanged: (value) {
          setState(() {
            _selectedPaymentId = value!;
            _paymentMethod = value.contains('cod') ? 'cod' :
            value.contains('momo') ? 'momo' : 'banking';
          });
        },
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : _textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? color.withOpacity(0.8) : _textSecondary,
            fontSize: 13,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : _textSecondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : _textSecondary,
            size: 20,
          ),
        ),
        activeColor: color,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectedProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: widget.selectedItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _backgroundColor,
                    image: item.anh.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(item.anh),
                      fit: BoxFit.cover,
                    )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: item.anh.isEmpty ? Icon(
                    Icons.shopping_bag_outlined,
                    color: _textSecondary.withOpacity(0.5),
                  ) : null,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenSanPham,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatPrice(item.giaBan)}đ x ${item.soLuong}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tồn kho: ${item.soLuongTon}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.soLuong > item.soLuongTon ? Colors.orange.shade600 : _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${_formatPrice(item.thanhTien)}đ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Tổng tiền hàng', widget.totalAmount),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildTotalRow('Giảm giá', -_discountAmount, isDiscount: true),
          ],
          const SizedBox(height: 10),
          _buildTotalRow('Phí vận chuyển', _shippingFee),
          const SizedBox(height: 10),
          _buildDivider(),
          const SizedBox(height: 10),
          _buildTotalRow('Tổng thanh toán', _finalAmount, isTotal: true),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessingPayment ? Colors.grey : _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _isProcessingPayment ? 0 : 3,
                shadowColor: _isProcessingPayment ? Colors.transparent : _primaryColor.withOpacity(0.4),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ĐẶT HÀNG NGAY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: _textSecondary.withOpacity(0.2),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _textPrimary : _textSecondary,
          ),
        ),
        Text(
          '${isDiscount && amount > 0 ? '-' : ''}${_formatPrice(amount)}đ',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? _primaryColor
                : isDiscount
                ? Colors.green
                : _textPrimary,
          ),
        ),
      ],
    );
  }
}