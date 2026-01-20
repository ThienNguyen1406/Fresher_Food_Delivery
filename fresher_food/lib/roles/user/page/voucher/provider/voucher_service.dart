import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/services/api/coupon_api.dart';

class VoucherService {
  final CouponApi _couponApi;

  VoucherService({CouponApi? couponApi})
      : _couponApi = couponApi ?? CouponApi();

  Future<List<PhieuGiamGia>> getAllCoupons() async {
    try {
      print('🔄 Service: Bắt đầu tải danh sách mã giảm giá...');
      final coupons = await _couponApi.getAllCoupons();
      print(' Service: Tải thành công ${coupons.length} mã giảm giá');
      return coupons;
    } catch (e) {
      print(' Service: Lỗi tải mã giảm giá: $e');
      throw Exception('Không thể tải danh sách mã giảm giá: $e');
    }
  }

  Future<List<PhieuGiamGia>> searchCoupons(String query) async {
    try {
      print('🔍 Service: Tìm kiếm mã giảm giá với từ khóa: $query');
      final searchResults = await _couponApi.searchCoupons(query);
      print(' Service: Tìm thấy ${searchResults.length} kết quả');
      return searchResults;
    } catch (e) {
      print(' Service: Lỗi tìm kiếm mã giảm giá: $e');
      throw Exception('Không thể tìm kiếm mã giảm giá: $e');
    }
  }
}