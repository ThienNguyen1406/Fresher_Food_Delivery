import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class CartService {
  final CartApi _cartApi = CartApi();
  final UserApi _userApi = UserApi();

  // User methods
  Future<bool> isLoggedIn() async {
    return await _userApi.isLoggedIn();
  }

  // Cart methods
  Future<CartResponse> getCart() async {
    return _cartApi.getCart();
  }

  Future<bool> removeFromCart(String productId) async {
    return await _cartApi.removeFromCart(productId);
  }

  Future<bool> updateCartItem(String productId, int quantity) async {
    return await _cartApi.updateCartItem(productId, quantity);
  }
}