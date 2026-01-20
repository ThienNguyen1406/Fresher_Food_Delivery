import 'dart:convert';

import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class RatingApi {
  // ==================== RATINGS ====================
// Lấy tất cả đánh giá
  Future<List<Rating>> getRatings() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Ratings'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Rating.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading ratings: $e');
    }
  }

// Lấy đánh giá theo sản phẩm
  Future<List<Rating>> getRatingsByProduct(String maSanPham) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Ratings/$maSanPham'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Rating.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // Không có đánh giá nào
      } else {
        throw Exception(
            'Failed to load product ratings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading product ratings: $e');
    }
  }

// Thêm đánh giá mới
  Future<bool> addRating(Rating rating) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Ratings'),
            headers: headers,
            body: json.encode(rating.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add rating');
      } else {
        throw Exception('Failed to add rating: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding rating: $e');
    }
  }

// Lấy thống kê đánh giá sản phẩm
  Future<RatingStats> getProductRatingStats(String maSanPham) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '${Constant().baseUrl}/Ratings/product/$maSanPham/average'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return RatingStats.fromJson(data);
      } else {
        throw Exception('Failed to load rating stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading rating stats: $e');
    }
  }

// Kiểm tra xem user đã đánh giá sản phẩm chưa
  Future<bool> hasUserRatedProduct(String maSanPham) async {
    try {
      final user = await UserApi().getCurrentUser();
      if (user == null) return false;

      final ratings = await getRatingsByProduct(maSanPham);
      return ratings.any((rating) => rating.maTaiKhoan == user.maTaiKhoan);
    } catch (e) {
      print('Error checking user rating: $e');
      return false;
    }
  }

// Lấy đánh giá của user cho sản phẩm cụ thể
  Future<Rating?> getUserRatingForProduct(String maSanPham) async {
    try {
      final user = await UserApi().getCurrentUser();
      if (user == null) return null;

      final ratings = await getRatingsByProduct(maSanPham);
      return ratings.firstWhere(
        (rating) => rating.maTaiKhoan == user.maTaiKhoan,
        orElse: () => Rating(
          maSanPham: maSanPham,
          maTaiKhoan: user.maTaiKhoan,
          soSao: 0,
        ),
      );
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

// Cập nhật đánh giá
  Future<bool> updateRating(Rating rating) async {
    try {
      final headers = await ApiService().getHeaders();
      // Đảm bảo có Content-Type header
      headers['Content-Type'] = 'application/json';
      
      print('🔄 Updating rating: ${rating.toJson()}');
      print('🔄 URL: ${Constant().baseUrl}/Ratings');
      
      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Ratings'),
            headers: headers,
            body: json.encode(rating.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      print(' Update Rating API Response: ${response.statusCode}');
      print(' Update Rating API Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không tìm thấy đánh giá để cập nhật');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Dữ liệu không hợp lệ');
      } else {
        throw Exception('Failed to update rating: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(' Error updating rating: $e');
      throw Exception('Error updating rating: $e');
    }
  }

// Xóa đánh giá
  Future<bool> deleteRating(String maSanPham) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      final response = await http
          .delete(
            Uri.parse(
                '${Constant().baseUrl}/Ratings/$maSanPham/${user.maTaiKhoan}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete rating: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting rating: $e');
    }
  }
}
