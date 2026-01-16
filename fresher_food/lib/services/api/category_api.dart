// ==================== CATEGORIES ====================

import 'dart:convert';
import 'dart:io';

import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class CategoryApi {
  Future<List<Category>> getCategories() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Category'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Categories API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} categories');

        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting categories: $e');
      throw Exception('Error getting categories: $e');
    }
  }

  Future<bool> addCategory(String tenDanhMuc, File? iconFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${Constant().baseUrl}/Category'));

      // Thêm các trường dữ liệu
      request.fields['TenDanhMuc'] = tenDanhMuc;

      // Thêm file ảnh nếu có
      if (iconFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('IconFile', iconFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Thêm danh mục thành công';
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi thêm danh mục: $e');
    }
  }

  Future<bool> updateCategory(String id, String tenDanhMuc, File? iconFile,
      {String? currentIconPath}) async {
    try {
      var request = http.MultipartRequest(
          'PUT', Uri.parse('${Constant().baseUrl}/Category/$id'));

      // Thêm các trường dữ liệu
      request.fields['TenDanhMuc'] = tenDanhMuc;
      if (currentIconPath != null) {
        request.fields['CurrentIconPath'] = currentIconPath;
      }

      // Thêm file ảnh nếu có
      if (iconFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('IconFile', iconFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Cập nhật danh mục thành công';
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi cập nhật danh mục: $e');
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Category/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Xóa danh mục thành công';
      } else if (response.statusCode == 400) {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['error'] ?? 'Không thể xóa danh mục');
      } else if (response.statusCode == 404) {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['error'] ?? 'Không tìm thấy danh mục');
      } else if (response.statusCode == 500) {
        final jsonResponse = json.decode(response.body);
        throw Exception(jsonResponse['error'] ?? 'Lỗi server khi xóa danh mục');
      } else {
        throw Exception('Lỗi xóa danh mục: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu đã là Exception thì rethrow, không wrap lại
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi xóa danh mục: $e');
    }
  }

  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Category/$categoryId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  Future<List<Category>> searchCategories(String keyword) async {
    try {
      final headers = await ApiService().getHeaders();
      final encodedKeyword = Uri.encodeComponent(keyword);

      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Category/search/$encodedKeyword'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Category/$categoryId/products'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Xử lý URL ảnh trước khi tạo Product
        final processedData = data.map((item) {
          if (item['anh'] != null && item['anh'].contains('localhost')) {
            item['anh'] = item['anh'].replaceAll('localhost', '10.0.2.2');
          }
          return item;
        }).toList();

        return processedData.map((e) => Product.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting products by category: $e');
    }
  }
}
