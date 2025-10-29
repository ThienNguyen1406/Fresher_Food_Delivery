import 'dart:convert';
import 'dart:io';

import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class ProductApi {
  Future<List<Product>> getProducts() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product'),
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
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi thêm sản phẩm: $e');
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
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi cập nhật sản phẩm: $e');
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id'),
      );

      if (response.statusCode == 200) {
        return response.body.contains('Xóa sản phẩm thành công');
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi xóa sản phẩm: $e');
    }
  }
}
