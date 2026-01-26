import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/models/Pay.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_service.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_state.dart';
import 'package:fresher_food/services/api/delivery_address_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutProvider with ChangeNotifier {
  final CheckoutService _service = CheckoutService();
  CheckoutState _state;

  CheckoutProvider({
    required List<CartItem> selectedItems,
    required double totalAmount,
  }) : _state = CheckoutState(
          selectedItems: selectedItems,
          totalAmount: totalAmount,
          finalAmount: totalAmount + 25000,
        );

  // Getters
  CheckoutState get state => _state;
  List<CartItem> get selectedItems => _state.selectedItems;
  double get totalAmount => _state.totalAmount;
  double get finalAmount => _state.finalAmount;
  double get discountAmount => _state.discountAmount;
  double get shippingFee => _state.shippingFee;
  bool get isLoading => _state.isLoading;
  bool get isProcessingPayment => _state.isProcessingPayment;
  bool get stripeCardComplete => _state.stripeCardComplete;
  PhieuGiamGia? get selectedCoupon => _state.selectedCoupon;
  List<Pay> get paymentMethods => _state.paymentMethods;
  String get paymentMethod => _state.paymentMethod;
  String get selectedPaymentId => _state.selectedPaymentId;

  // State update methods
  void updateName(String name) {
    _state = _state.copyWith(name: name);
    notifyListeners();
  }

  void updatePhone(String phone) {
    _state = _state.copyWith(phone: phone);
    notifyListeners();
  }

  void updateAddress(String address) {
    _state = _state.copyWith(address: address);
    notifyListeners();
  }

  void updateNote(String note) {
    _state = _state.copyWith(note: note);
    notifyListeners();
  }

  void updatePaymentMethod(String paymentMethod, String selectedPaymentId) {
    _state = _state.copyWith(
      paymentMethod: paymentMethod,
      selectedPaymentId: selectedPaymentId,
    );
    notifyListeners();
  }

  void updateLoading(bool isLoading) {
    _state = _state.copyWith(isLoading: isLoading);
    notifyListeners();
  }

  void updateProcessingPayment(bool isProcessingPayment) {
    _state = _state.copyWith(isProcessingPayment: isProcessingPayment);
    notifyListeners();
  }

  void setStripeCardComplete(bool value) {
    // ❌ KHÔNG gọi notifyListeners() vì sẽ rebuild CardFormField → mất dữ liệu thẻ
    // Chỉ update state để validation check khi user bấm "Đặt hàng"
    _state = _state.copyWith(stripeCardComplete: value);
    // notifyListeners(); // ❌ XÓA - không rebuild UI
  }

  // Business logic methods
  Future<void> loadUserInfo() async {
    try {
      updateLoading(true);
      final userInfo = await _service.loadUserInfo();
      
      // Thử load địa chỉ mặc định từ API trước
      String name = userInfo['hoTen'] ?? '';
      String phone = userInfo['sdt'] ?? '';
      String address = userInfo['diaChi'] ?? '';
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final maTaiKhoan = prefs.getString('maTaiKhoan') ?? userInfo['maTaiKhoan'] ?? '';
        if (maTaiKhoan.isNotEmpty) {
          final deliveryAddressApi = DeliveryAddressApi();
          final defaultAddress = await deliveryAddressApi.getDefaultAddress(maTaiKhoan);
          if (defaultAddress != null) {
            name = defaultAddress.hoTen;
            phone = defaultAddress.soDienThoai;
            address = defaultAddress.diaChi;
          }
        }
      } catch (e) {
        // Nếu không load được địa chỉ từ API, dùng thông tin user
        print('Không thể load địa chỉ mặc định: $e');
      }

      _state = _state.copyWith(
        name: name,
        phone: phone,
        address: address,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      updateLoading(false);
    }
  }

  Future<void> loadPaymentMethods() async {
    try {
      final paymentMethods = await _service.loadPaymentMethods();

      String selectedPaymentId = '';
      String paymentMethod = 'cod'; // Mặc định là COD

      if (paymentMethods.isNotEmpty) {
        // Tìm COD method trước
        final codMethod = paymentMethods.firstWhere(
          (pay) {
            final payName = pay.Pay_name.toLowerCase();
            return payName.contains('cod') || 
                   payName.contains('tiền mặt') || 
                   payName.contains('khi nhận hàng') ||
                   payName.contains('thanh toán khi nhận');
          },
          orElse: () => paymentMethods.first,
        );
        
        selectedPaymentId = codMethod.Id_Pay;
        final payName = codMethod.Pay_name.toLowerCase();
        
        // Xác định payment method từ tên
        if (payName.contains('cod') || 
            payName.contains('tiền mặt') || 
            payName.contains('khi nhận hàng') ||
            payName.contains('thanh toán khi nhận')) {
          paymentMethod = 'cod';
        } else if (payName.contains('banking') || 
                   payName.contains('bank') || 
                   payName.contains('chuyển khoản') || 
                   payName.contains('transfer') ||
                   payName.contains('ngân hàng')) {
          paymentMethod = 'banking';
        } else if (payName.contains('momo')) {
          paymentMethod = 'momo';
        } else if (payName.contains('stripe') || 
                   payName.contains('thẻ') || 
                   payName.contains('card') || 
                   payName.contains('credit') ||
                   payName.contains('debit')) {
          paymentMethod = 'stripe';
        }
        // Nếu không match, giữ mặc định là 'cod'
      }

      _state = _state.copyWith(
        paymentMethods: paymentMethods,
        selectedPaymentId: selectedPaymentId,
        paymentMethod: paymentMethod,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadAvailableCoupons() async {
    try {
      final coupons = await _service.loadAvailableCoupons();
      _state = _state.copyWith(availableCoupons: coupons);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void applyCoupon(PhieuGiamGia coupon) {
    final newDiscountAmount = coupon.giaTri;
    final newFinalAmount = _service.calculateFinalAmount(
      _state.totalAmount,
      newDiscountAmount,
      _state.shippingFee,
    );

    _state = _state.copyWith(
      selectedCoupon: coupon,
      discountAmount: newDiscountAmount,
      finalAmount: newFinalAmount,
    );
    notifyListeners();
  }

  void removeCoupon() {
    print('removeCoupon được gọi');
    print('Trước khi xóa - selectedCoupon: ${_state.selectedCoupon?.code}');
    
    final newFinalAmount = _service.calculateFinalAmount(
      _state.totalAmount,
      0.0,
      _state.shippingFee,
    );

    _state = _state.copyWith(
      clearCoupon: true,
      discountAmount: 0.0,
      finalAmount: newFinalAmount,
    );
    
    print('Sau khi xóa - selectedCoupon: ${_state.selectedCoupon}');
    print('Final amount mới: $newFinalAmount');
    
    notifyListeners();
    print('Đã gọi notifyListeners');
  }

  void updateFinalAmount() {
    final newFinalAmount = _service.calculateFinalAmount(
      _state.totalAmount,
      _state.discountAmount,
      _state.shippingFee,
    );

    _state = _state.copyWith(finalAmount: newFinalAmount);
    notifyListeners();
  }

  // Validation
  bool validateForm() {
    return _state.name.trim().isNotEmpty &&
        _state.phone.trim().isNotEmpty &&
        _state.address.trim().isNotEmpty;
  }

  bool validateStock() {
    for (var item in _state.selectedItems) {
      if (item.soLuong > item.soLuongTon) {
        return false;
      }
    }
    return true;
  }

  CartItem? getOutOfStockItem() {
    for (var item in _state.selectedItems) {
      if (item.soLuong > item.soLuongTon) {
        return item;
      }
    }
    return null;
  }

  // Order creation
  Future<bool> createOrder(String paymentMethod) async {
    try {
      final userInfo = await _service.loadUserInfo();
      final maTaiKhoan = userInfo['maTaiKhoan'];

      if (maTaiKhoan == null || maTaiKhoan.isEmpty) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final order = Order(
        maDonHang: '',
        maTaiKhoan: maTaiKhoan,
        ngayDat: DateTime.now(),
        trangThai: 'pending',
        diaChiGiaoHang: _state.address.trim(),
        soDienThoai: _state.phone.trim(),
        ghiChu: _state.note.trim(),
        phuongThucThanhToan: paymentMethod,
        trangThaiThanhToan: paymentMethod == 'cod' ? 'pending' : 'paid',
        id_PhieuGiamGia: _state.selectedCoupon?.idPhieuGiamGia ?? '',
        id_Pay: _state.selectedPaymentId,
      );

      final orderDetails = _state.selectedItems.map((item) {
        return OrderDetail(
          maDonHang: '',
          maSanPham: item.maSanPham,
          tenSanPham: item.tenSanPham,
          giaBan: item.giaBan,
          soLuong: item.soLuong,
        );
      }).toList();

      return await _service.createOrderAndClearCart(
        order: order,
        orderDetails: orderDetails,
      );
    } catch (e) {
      rethrow;
    }
  }

  String formatPrice(double price) {
    return _service.formatPrice(price);
  }
}
