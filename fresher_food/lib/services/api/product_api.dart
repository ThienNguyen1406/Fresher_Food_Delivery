import 'dart:convert';
import 'dart:io';

import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class ProductApi {
  /// Lấy danh sách sản phẩm
  /// [originalPrice]: true = trả về giá gốc (cho admin), false = trả về giá đã giảm (cho user)
  Future<List<Product>> getProducts({bool originalPrice = false}) async {
    try {
      final uri = originalPrice 
          ? Uri.parse('${Constant().baseUrl}/Product?originalPrice=true')
          : Uri.parse('${Constant().baseUrl}/Product');
      
      final res = await http
          .get(
            uri,
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return (jsonDecode(res.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product/$id'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to load product $id: ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) return Product.fromJson(data.first);
      if (data is Map<String, dynamic>) return Product.fromJson(data);

      print('Unexpected format for $id: ${data.runtimeType}');
      return null;
    } catch (e) {
      print('Error fetching $id: $e');
      return null;
    }
  }

  //search products by name
  Future<List<Product>> searchProducts(String name) async {
    final response = await http
        .get(Uri.parse('${Constant().baseUrl}/Product/Search?name=$name'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Không tìm thấy sản phẩm');
    }
  }

// Trong ApiService class
  Future<bool> addProduct(Product product, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${Constant().baseUrl}/Product'));

      // Thêm các trường dữ liệu
      request.fields['TenSanPham'] = product.tenSanPham;
      request.fields['MoTa'] = product.moTa;
      request.fields['GiaBan'] = product.giaBan.toString();
      request.fields['SoLuongTon'] = product.soLuongTon.toString();
      request.fields['XuatXu'] = product.xuatXu;
      request.fields['DonViTinh'] = product.donViTinh;
      request.fields['MaDanhMuc'] = product.maDanhMuc;
      
      // Thêm ngày sản xuất và hạn sử dụng
      if (product.ngaySanXuat != null) {
        request.fields['NgaySanXuat'] = product.ngaySanXuat!.toIso8601String();
      }
      if (product.ngayHetHan != null) {
        request.fields['NgayHetHan'] = product.ngayHetHan!.toIso8601String();
      }

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('Anh', imageFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Thêm sản phẩm thành công';
      } else if (response.statusCode == 400) {
        // Xử lý lỗi validation từ backend
        try {
          final errorData = json.decode(responseData);
          if (errorData['error'] != null) {
            throw Exception(errorData['error']);
          }
        } catch (_) {
          // Nếu không parse được JSON, dùng message mặc định
        }
        throw Exception('Dữ liệu không hợp lệ');
      }
      return false;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> updateProduct(
      String id, Product product, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'PUT', Uri.parse('${Constant().baseUrl}/Product/$id'));

      // Thêm các trường dữ liệu
      request.fields['TenSanPham'] = product.tenSanPham;
      request.fields['MoTa'] = product.moTa;
      request.fields['GiaBan'] = product.giaBan.toString();
      request.fields['SoLuongTon'] = product.soLuongTon.toString();
      request.fields['XuatXu'] = product.xuatXu;
      request.fields['DonViTinh'] = product.donViTinh;
      request.fields['MaDanhMuc'] = product.maDanhMuc;
      
      // Thêm ngày sản xuất và hạn sử dụng
      if (product.ngaySanXuat != null) {
        request.fields['NgaySanXuat'] = product.ngaySanXuat!.toIso8601String();
      }
      if (product.ngayHetHan != null) {
        request.fields['NgayHetHan'] = product.ngayHetHan!.toIso8601String();
      }

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('Anh', imageFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Cập nhật sản phẩm thành công';
      } else if (response.statusCode == 400) {
        // Xử lý lỗi validation từ backend
        try {
          final errorData = json.decode(responseData);
          if (errorData['error'] != null) {
            throw Exception(errorData['error']);
          }
        } catch (_) {
          // Nếu không parse được JSON, dùng message mặc định
        }
        throw Exception('Dữ liệu không hợp lệ');
      }
      return false;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Delete Product API Response: ${response.statusCode}');
      print('Delete Product API Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map && jsonResponse['message'] != null) {
            // Chấp nhận cả "Xóa sản phẩm thành công" và "Đã chuyển sản phẩm vào thùng rác"
            return jsonResponse['message'].toString().contains('thành công') ||
                   jsonResponse['message'].toString().contains('thùng rác');
          }
        } catch (e) {
          // Nếu không parse được JSON, kiểm tra string
          return response.body.contains('thành công') || response.body.contains('thùng rác');
        }
        return true;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Không thể xóa sản phẩm');
        } catch (e) {
          throw Exception('Không thể xóa sản phẩm: ${response.body}');
        }
      } else {
        throw Exception('Failed to delete product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Lỗi xóa sản phẩm: $e');
    }
  }

  // Lấy danh sách sản phẩm trong thùng rác
  Future<List<Map<String, dynamic>>> getTrashProducts() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product/Trash'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load trash products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting trash products: $e');
      throw Exception('Lỗi lấy danh sách thùng rác: $e');
    }
  }

  // Khôi phục sản phẩm từ thùng rác
  Future<bool> restoreProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.post(
        Uri.parse('${Constant().baseUrl}/Product/$id/Restore'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Khôi phục sản phẩm thành công';
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không tìm thấy sản phẩm trong thùng rác');
      } else {
        throw Exception('Failed to restore product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error restoring product: $e');
      throw Exception('Lỗi khôi phục sản phẩm: $e');
    }
  }

  // Xóa vĩnh viễn sản phẩm từ thùng rác
  Future<bool> permanentDeleteProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id/Permanent'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Đã xóa vĩnh viễn sản phẩm';
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Xử lý lỗi validation từ backend
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            throw Exception(errorData['error']);
          }
        } catch (_) {
          // Nếu không parse được JSON, dùng message mặc định
        }
        throw Exception('Không thể xóa vĩnh viễn sản phẩm');
      } else {
        throw Exception('Lỗi xóa vĩnh viễn sản phẩm: ${response.statusCode}');
      }
    } catch (e) {
      print('Error permanent deleting product: $e');
      // Nếu đã là Exception với message rõ ràng, throw lại
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi xóa vĩnh viễn sản phẩm: $e');
    }
  }
}
