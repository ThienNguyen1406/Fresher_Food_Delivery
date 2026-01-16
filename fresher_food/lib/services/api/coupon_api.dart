import 'dart:convert';

import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class CouponApi {
  //===================== COUPONS ====================
  // GET: Lấy tất cả phiếu giảm giá (chỉ lấy những voucher user chưa sử dụng)
  Future<List<PhieuGiamGia>> getAllCoupons() async {
    try {
      final headers = await ApiService().getHeaders();
      
      // Lấy thông tin user hiện tại để lọc voucher đã sử dụng
      final user = await UserApi().getCurrentUser();
      String? maTaiKhoan = user?.maTaiKhoan;
      
      // Tạo URL với query parameter maTaiKhoan nếu có
      String url = '${Constant().baseUrl}/Coupon';
      if (maTaiKhoan != null && maTaiKhoan.isNotEmpty) {
        url += '?maTaiKhoan=${Uri.encodeComponent(maTaiKhoan)}';
      }
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Coupons API Response: ${response.statusCode}');
      print('Coupons API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} coupons for user: $maTaiKhoan');

        return data.map((e) => PhieuGiamGia.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupons: $e');
      throw Exception('Error getting coupons: $e');
    }
  }

  // GET: Tìm kiếm phiếu giảm giá theo code
  Future<List<PhieuGiamGia>> searchCoupons(String code) async {
    try {
      final headers = await ApiService().getHeaders();
      final encodedCode = Uri.encodeComponent(code);

      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Coupon/Search?code=$encodedCode'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Search Coupons API Response: ${response.statusCode}');
      print(
          'Search Coupons URL: ${Constant().baseUrl}/Coupon/Search?code=$encodedCode');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} coupons for code: $code');

        return data.map((e) => PhieuGiamGia.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        print('No coupons found for code: $code');
        return [];
      } else {
        throw Exception('Failed to search coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching coupons: $e');
      throw Exception('Error searching coupons: $e');
    }
  }

  // GET: Lấy phiếu giảm giá theo ID
  Future<PhieuGiamGia> getCouponById(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Coupon/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Coupon by ID API Response: ${response.statusCode}');
      print('Coupon by ID API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PhieuGiamGia.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy phiếu giảm giá');
      } else {
        throw Exception('Failed to load coupon: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupon by ID: $e');
      throw Exception('Error getting coupon by ID: $e');
    }
  }

  // GET: Lấy phiếu giảm giá theo mã code
  Future<PhieuGiamGia> getCouponByCode(String code) async {
    try {
      final headers = await ApiService().getHeaders();
      final encodedCode = Uri.encodeComponent(code);

      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Coupon/Code/$encodedCode'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Coupon by Code API Response: ${response.statusCode}');
      print('Coupon by Code API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PhieuGiamGia.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy phiếu giảm giá với mã này');
      } else {
        throw Exception(
            'Failed to load coupon by code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupon by code: $e');
      throw Exception('Error getting coupon by code: $e');
    }
  }

// POST: Thêm phiếu giảm giá mới
  Future<String> createCoupon(PhieuGiamGia coupon) async {
    final headers = await ApiService().getHeaders();
    final requestData = {
      'code': coupon.code,
      'giaTri': coupon.giaTri,
      'moTa': coupon.moTa,
      'loaiGiaTri': coupon.loaiGiaTri,
      'soLuongToiDa': coupon.soLuongToiDa,
      'soLuongDaSuDung': coupon.soLuongDaSuDung,
    };

    final response = await http
        .post(
          Uri.parse('${Constant().baseUrl}/Coupon'),
          headers: headers,
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return "Thêm thành công";
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Thêm phiếu giảm giá thất bại');
    }
  }

// PUT: Cập nhật phiếu giảm giá
  Future<String> updateCoupon(String id, PhieuGiamGia coupon) async {
    final headers = await ApiService().getHeaders();
    final requestData = {
      'code': coupon.code,
      'giaTri': coupon.giaTri,
      'moTa': coupon.moTa,
      'loaiGiaTri': coupon.loaiGiaTri,
      'soLuongToiDa': coupon.soLuongToiDa,
      'soLuongDaSuDung': coupon.soLuongDaSuDung,
    };

    final response = await http
        .put(
          Uri.parse('${Constant().baseUrl}/Coupon/$id'),
          headers: headers,
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return "Cập nhật thành công";
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phiếu giảm giá để cập nhật');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Cập nhật phiếu giảm giá thất bại');
    }
  }

  // DELETE: Xóa phiếu giảm giá
  Future<bool> deleteCoupon(String id) async {
    final res =
        await http.delete(Uri.parse('${Constant().baseUrl}/Coupon/$id'));
    return res.statusCode == 200;
  }

  // Kiểm tra tính hợp lệ của phiếu giảm giá
  Future<bool> validateCoupon(String code) async {
    try {
      final coupon = await getCouponByCode(code);
      return coupon.idPhieuGiamGia.isNotEmpty;
    } catch (e) {
      print('Coupon validation failed: $e');
      return false;
    }
  }

  // Áp dụng phiếu giảm giá vào đơn hàng
  Future<double> applyCouponToOrder(String code, double totalAmount) async {
    try {
      final coupon = await getCouponByCode(code);

      if (coupon.idPhieuGiamGia.isEmpty) {
        throw Exception('Mã giảm giá không hợp lệ');
      }

      // Tính toán số tiền giảm giá dựa trên loại giảm giá
      double discountAmount = 0.0;

      if (coupon.loaiGiaTri == 'Percent') {
        // Giảm giá theo phần trăm
        discountAmount = totalAmount * (coupon.giaTri / 100);
      } else {
        // Giảm giá theo số tiền cố định (Amount)
        discountAmount = coupon.giaTri;
      }

      // Đảm bảo số tiền giảm không vượt quá tổng đơn hàng
      if (discountAmount > totalAmount) {
        discountAmount = totalAmount;
      }

      return discountAmount;
    } catch (e) {
      print('Error applying coupon: $e');
      throw Exception('Không thể áp dụng mã giảm giá: $e');
    }
  }

  // Lấy số lượng phiếu giảm giá
  Future<int> getCouponCount() async {
    try {
      final coupons = await getAllCoupons();
      return coupons.length;
    } catch (e) {
      print('Error getting coupon count: $e');
      return 0;
    }
  }

  // Kiểm tra xem mã giảm giá có tồn tại không (dùng cho validation)
  Future<bool> checkCouponExists(String code) async {
    try {
      final coupons = await searchCoupons(code);
      return coupons.isNotEmpty;
    } catch (e) {
      print('Error checking coupon existence: $e');
      return false;
    }
  }
}
