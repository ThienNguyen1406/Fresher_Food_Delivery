import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/favorite_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class HomeService {
  final CategoryApi _categoryApi = CategoryApi();
  final ProductApi _productApi = ProductApi();
  final FavoriteApi _favoriteApi = FavoriteApi();
  final CartApi _cartApi = CartApi();
  final UserApi _userApi = UserApi();

  // Categories
  Future<List<Category>> getCategories() async {
    return await _categoryApi.getCategories();
  }

  // Products
  Future<List<Product>> getProducts() async {
    return await _productApi.getProducts();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    if (categoryId == 'all') {
      return await _productApi.getProducts();
    } else {
      return await _categoryApi.getProductsByCategory(categoryId);
    }
  }

  Future<List<Product>> searchProducts(String keyword) async {
    return await _productApi.searchProducts(keyword);
  }

  // Favorites
  Future<List<Product>> getFavorites() async {
    return await _favoriteApi.getFavorites();
  }

  Future<bool> addToFavorites(String productId) async {
    return await _favoriteApi.addToFavorites(productId);
  }

  Future<bool> removeFromFavorites(String productId) async {
    return await _favoriteApi.removeFromFavoritesByProductId(productId);
  }

  // Cart
  Future<bool> addToCart(String productId, int quantity) async {
    return await _cartApi.addToCart(productId, quantity);
  }

  // User
  Future<bool> isLoggedIn() async {
    return await _userApi.isLoggedIn();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return await _userApi.getUserInfo();
  }
}
