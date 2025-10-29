import 'dart:convert';

import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class FavoriteApi {
  // ==================== FAVORITES ====================

  Future<bool> addToFavorites(String productId) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Favorite'),
            headers: headers,
            body: jsonEncode({
              'maTaiKhoan': user.maTaiKhoan,
              'maSanPham': productId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error adding to favorites: $e');
    }
  }

  Future<List<Product>> getFavorites() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      print('Fetching favorites for user: ${user.maTaiKhoan}');
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Favorite/User/${user.maTaiKhoan}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Favorites API Response: ${response.statusCode}');
      print('Favorites API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Favorites data: $data');

        final List<String> productIds = [];
        for (var item in data) {
          if (item is Map<String, dynamic> && item.containsKey('maSanPham')) {
            productIds.add(item['maSanPham'].toString());
          }
        }

        print('Product IDs from favorites: $productIds');

        final List<Product> products = [];
        for (var productId in productIds) {
          try {
            final product = await ProductApi().getProductById(productId);
            if (product != null) {
              print('Loaded product: ${product.tenSanPham}');
              products.add(product);
            }
          } catch (e) {
            print('Error loading product $productId: $e');
          }
        }

        print('Converted ${products.length} products');
        return products;
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting favorites: $e');
      throw Exception('Error getting favorites: $e');
    }
  }

  // Lấy số lượng sản phẩm yêu thích bằng cách đếm từ danh sách
  Future<int> getFavoriteCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('Error getting favorite count: $e');
      return 0;
    }
  }

  Future<bool> removeFromFavoritesByProductId(String productId) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      final response = await http
          .delete(
            Uri.parse(
                '${Constant().baseUrl}/Favorite/Product/${user.maTaiKhoan}/$productId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error removing from favorites: $e');
    }
  }
}
