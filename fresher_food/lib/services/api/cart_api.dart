import 'dart:convert';

import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class CartApi {
   // ==================== CART ====================
  Future<CartResponse> getCart() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      print('Fetching cart for user: ${user.maTaiKhoan}');
      final response = await http.get(
        Uri.parse('${Constant().baseUrl}/Carts/user/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Cart API Response: ${response.statusCode}');
      print('Cart API Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Cart data: $data');
        
        final cartResponse = CartResponse.fromJson(data);
        print('Converted ${cartResponse.sanPham.length} cart items');
        return cartResponse;
      } else {
        throw Exception('Failed to load cart: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting cart: $e');
      throw Exception('Error getting cart: $e');
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('${Constant().baseUrl}/Carts/add'),
        headers: headers,
        body: jsonEncode({
          'maTaiKhoan': user.maTaiKhoan,
          'maSanPham': productId,
          'soLuong': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }

  Future<bool> removeFromCart(String productId) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Carts/remove/${user.maTaiKhoan}/$productId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to remove from cart');
      }
    } catch (e) {
      throw Exception('Error removing from cart: $e');
    }
  }

  Future<bool> updateCartItem(String productId, int quantity) async {
    try {
      final headers =await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.put(
        Uri.parse('${Constant().baseUrl}/Carts/update-quantity'),
        headers: headers,
        body: jsonEncode({
          'maTaiKhoan': user.maTaiKhoan,
          'maSanPham': productId,
          'soLuong': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  Future<bool> clearCart() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Carts/clear/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
      return false;
    }
  }
}