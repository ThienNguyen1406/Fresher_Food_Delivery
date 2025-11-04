import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/models/Pay.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/payment_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class CheckoutService {
  // Load user info
  Future<Map<String, dynamic>> loadUserInfo() async {
    try {
      return await UserApi().getUserInfo();
    } catch (e) {
      throw Exception('Lỗi tải thông tin người dùng: $e');
    }
  }

  // Load payment methods
  Future<List<Pay>> loadPaymentMethods() async {
    try {
      return await PaymentApi().getPay();
    } catch (e) {
      throw Exception('Lỗi tải phương thức thanh toán: $e');
    }
  }

  // Load available coupons
  Future<List<PhieuGiamGia>> loadAvailableCoupons() async {
    try {
      return await CouponApi().getAllCoupons();
    } catch (e) {
      throw Exception('Lỗi tải mã giảm giá: $e');
    }
  }

  // Create order and clear cart
  Future<bool> createOrderAndClearCart({
    required Order order,
    required List<OrderDetail> orderDetails,
  }) async {
    try {
      final orderSuccess = await OrderApi().createOrder(order, orderDetails);
      
      if (!orderSuccess) {
        throw Exception('Không thể tạo đơn hàng');
      }

      // Clear cart after successful order creation
      try {
        await CartApi().clearCart();
      } catch (e) {
        print('⚠️ Lỗi khi clear giỏ hàng: $e');
        // Still return true because order was created successfully
      }
      
      return true;
    } catch (e) {
      throw Exception('Lỗi tạo đơn hàng: $e');
    }
  }

  // Calculate final amount
  double calculateFinalAmount(double totalAmount, double discountAmount, double shippingFee) {
    return (totalAmount - discountAmount + shippingFee).clamp(0, double.infinity);
  }

  // Format price for display
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}