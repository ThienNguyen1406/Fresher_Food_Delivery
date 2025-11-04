import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/favorite_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class FavoriteService {
  final FavoriteApi _favoriteApi = FavoriteApi();
  final UserApi _userApi = UserApi();

  // Check login status
  Future<bool> checkLoginStatus() async {
    try {
      return await _userApi.isLoggedIn();
    } catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái đăng nhập: $e');
    }
  }

  // Load favorites
  Future<List<Product>> loadFavorites() async {
    try {
      return await _favoriteApi.getFavorites();
    } catch (e) {
      throw Exception('Lỗi tải danh sách yêu thích: $e');
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(String productId) async {
    try {
      return await _favoriteApi.removeFromFavoritesByProductId(productId);
    } catch (e) {
      throw Exception('Lỗi xóa khỏi danh sách yêu thích: $e');
    }
  }

  // Format price
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}