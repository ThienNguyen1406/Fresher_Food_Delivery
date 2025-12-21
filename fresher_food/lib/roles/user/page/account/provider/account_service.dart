import 'package:fresher_food/services/api/favorite_api.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class AccountService {
  final UserApi _userApi = UserApi();
  final OrderApi _orderApi = OrderApi();
  final FavoriteApi _favoriteApi = FavoriteApi();

  // User methods
  Future<bool> isLoggedIn() async {
    return await _userApi.isLoggedIn();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return await _userApi.getUserInfo();
  }

  Future<bool> logout() async {
    return await _userApi.logout();
  }

  // Statistics methods
  Future<int> getOrderCount() async {
    return await _orderApi.getOrderCount();
  }

  Future<int> getFavoriteCount() async {
    return await _favoriteApi.getFavoriteCount();
  }

  // Lấy danh sách sản phẩm từ đơn hàng đã hoàn thành để đánh giá
  Future<List<Map<String, dynamic>>> getPurchasedProducts() async {
    try {
      // Gọi API để lấy sản phẩm từ đơn hàng đã hoàn thành
      final products = await _orderApi.getCompletedOrderProducts();
      return products;
    } catch (e) {
      print('Error getting purchased products: $e');
      // Trả về danh sách rỗng nếu có lỗi
      return [];
    }
  }
}