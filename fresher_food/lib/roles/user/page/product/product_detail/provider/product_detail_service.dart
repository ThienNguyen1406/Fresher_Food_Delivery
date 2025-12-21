// services/productdetail_service.dart
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/favorite_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/rating_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class ProductDetailService {
  final ProductApi _productApi = ProductApi();
  final FavoriteApi _favoriteApi = FavoriteApi();
  final CartApi _cartApi = CartApi();
  final RatingApi _ratingApi = RatingApi();
  final UserApi _userApi = UserApi();

  Future<Product?> getProductDetail(String productId) async {
    try {
      return await _productApi.getProductById(productId);
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết sản phẩm: $e');
    }
  }

  Future<bool> checkFavoriteStatus(String productId) async {
    try {
      final isLoggedIn = await _userApi.isLoggedIn();
      if (!isLoggedIn) return false;
      
      final favorites = await _favoriteApi.getFavorites();
      return favorites.any((p) => p.maSanPham == productId);
    } catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái yêu thích: $e');
    }
  }

  Future<bool> toggleFavorite(String productId, bool currentStatus) async {
    try {
      final isLoggedIn = await _userApi.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập để sử dụng tính năng này');
      }

      if (currentStatus) {
        await _favoriteApi.removeFromFavoritesByProductId(productId);
        return false;
      } else {
        await _favoriteApi.addToFavorites(productId);
        return true;
      }
    } catch (e) {
      throw Exception('Lỗi khi thay đổi trạng thái yêu thích: $e');
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    try {
      return await _cartApi.addToCart(productId, quantity);
    } catch (e) {
      throw Exception('Lỗi khi thêm vào giỏ hàng: $e');
    }
  }

  // Rating methods
  Future<RatingStats> getRatingStats(String productId) async {
    try {
      return await _ratingApi.getProductRatingStats(productId);
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê đánh giá: $e');
    }
  }

  Future<List<Rating>> getRatingsByProduct(String productId) async {
    try {
      return await _ratingApi.getRatingsByProduct(productId);
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách đánh giá: $e');
    }
  }

  Future<Rating?> getUserRating(String productId) async {
    try {
      return await _ratingApi.getUserRatingForProduct(productId);
    } catch (e) {
      throw Exception('Lỗi khi tải đánh giá của người dùng: $e');
    }
  }

  Future<bool> submitRating(Rating rating) async {
    try {
      final user = await _userApi.getCurrentUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đánh giá');
      }

      // Đảm bảo maTaiKhoan được điền đúng
      final ratingWithUser = Rating(
        maSanPham: rating.maSanPham,
        maTaiKhoan: user.maTaiKhoan, // Điền maTaiKhoan từ user
        soSao: rating.soSao,
        noiDung: rating.noiDung,
      );

      final existingRating = await _ratingApi.getUserRatingForProduct(rating.maSanPham);
      if (existingRating != null && existingRating.soSao > 0) {
        // Cập nhật đánh giá
        return await _ratingApi.updateRating(ratingWithUser);
      } else {
        // Thêm đánh giá mới
        return await _ratingApi.addRating(ratingWithUser);
      }
    } catch (e) {
      throw Exception('Lỗi khi gửi đánh giá: $e');
    }
  }

  Future<bool> deleteRating(String productId) async {
    try {
      return await _ratingApi.deleteRating(productId);
    } catch (e) {
      throw Exception('Lỗi khi xóa đánh giá: $e');
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      return await _userApi.isLoggedIn();
    } catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái đăng nhập: $e');
    }
  }
}