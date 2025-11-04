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

  // Purchased products (tạm thời)
  Future<List<Map<String, dynamic>>> getPurchasedProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập delay
    
    // Dữ liệu mẫu - thay thế bằng API call thực tế
    return [
      {
        'maSanPham': 'SP001',
        'tenSanPham': 'iPhone 14 Pro Max',
        'anh': 'https://example.com/iphone14.jpg'
      },
      {
        'maSanPham': 'SP002', 
        'tenSanPham': 'Samsung Galaxy S23',
        'anh': 'https://example.com/galaxy-s23.jpg'
      },
      {
        'maSanPham': 'SP003',
        'tenSanPham': 'MacBook Air M2',
        'anh': 'https://example.com/macbook-air.jpg'
      },
    ];
  }
}