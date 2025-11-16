import 'dart:convert';
import 'package:fresher_food/models/Sale.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class SaleApi {
  /// Lấy danh sách tất cả khuyến mãi
  Future<List<Sale>> getAllSales() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Sale'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get sales: ${res.statusCode}');
        return [];
      }

      final response = jsonDecode(res.body);
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Sale.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  /// Lấy khuyến mãi theo ID
  Future<Sale?> getSaleById(String id) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Sale/$id'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get sale: ${res.statusCode}');
        return null;
      }

      final response = jsonDecode(res.body);
      if (response['data'] != null) {
        return Sale.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error getting sale: $e');
      return null;
    }
  }

  /// Tạo khuyến mãi mới
  Future<Map<String, dynamic>?> createSale(Sale sale) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Sale'),
            headers: await ApiService().getHeaders(),
            body: jsonEncode(sale.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? 'Failed to create sale');
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error creating sale: $e');
      rethrow;
    }
  }

  /// Cập nhật khuyến mãi
  Future<Map<String, dynamic>?> updateSale(String id, Sale sale) async {
    try {
      final res = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Sale/$id'),
            headers: await ApiService().getHeaders(),
            body: jsonEncode(sale.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? 'Failed to update sale');
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error updating sale: $e');
      rethrow;
    }
  }

  /// Xóa khuyến mãi
  Future<bool> deleteSale(String id) async {
    try {
      final res = await http
          .delete(
            Uri.parse('${Constant().baseUrl}/Sale/$id'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to delete sale: ${res.statusCode}');
        return false;
      }

      return true;
    } catch (e) {
      print('Error deleting sale: $e');
      return false;
    }
  }

  /// Lấy khuyến mãi theo sản phẩm
  Future<List<Sale>> getSalesByProduct(String maSanPham) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Sale/product/$maSanPham'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get sales by product: ${res.statusCode}');
        return [];
      }

      final response = jsonDecode(res.body);
      if (response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Sale.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting sales by product: $e');
      return [];
    }
  }
}

