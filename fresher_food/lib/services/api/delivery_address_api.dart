import 'dart:convert';
import 'package:fresher_food/models/DeliveryAddress.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class DeliveryAddressApi {
  // GET: Lấy danh sách địa chỉ của user
  Future<List<DeliveryAddress>> getDeliveryAddresses(String maTaiKhoan) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/DeliveryAddress/$maTaiKhoan'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DeliveryAddress.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi lấy danh sách địa chỉ: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting delivery addresses: $e');
      rethrow;
    }
  }

  // GET: Lấy địa chỉ mặc định
  Future<DeliveryAddress?> getDefaultAddress(String maTaiKhoan) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/DeliveryAddress/$maTaiKhoan/default'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DeliveryAddress.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Không có địa chỉ mặc định
      } else {
        throw Exception('Lỗi lấy địa chỉ mặc định: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting default address: $e');
      rethrow;
    }
  }

  // POST: Tạo địa chỉ mới
  Future<String> createDeliveryAddress({
    required String maTaiKhoan,
    required String hoTen,
    required String soDienThoai,
    required String diaChi,
    required bool laDiaChiMacDinh,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/DeliveryAddress'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'maTaiKhoan': maTaiKhoan,
              'hoTen': hoTen,
              'soDienThoai': soDienThoai,
              'diaChi': diaChi,
              'laDiaChiMacDinh': laDiaChiMacDinh,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['maDiaChi'] ?? '';
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Lỗi tạo địa chỉ');
      }
    } catch (e) {
      print('Error creating delivery address: $e');
      rethrow;
    }
  }

  // PUT: Cập nhật địa chỉ
  Future<void> updateDeliveryAddress({
    required String maDiaChi,
    required String hoTen,
    required String soDienThoai,
    required String diaChi,
    required bool laDiaChiMacDinh,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/DeliveryAddress/$maDiaChi'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'maTaiKhoan': '', // Không cần trong update
              'hoTen': hoTen,
              'soDienThoai': soDienThoai,
              'diaChi': diaChi,
              'laDiaChiMacDinh': laDiaChiMacDinh,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Lỗi cập nhật địa chỉ');
      }
    } catch (e) {
      print('Error updating delivery address: $e');
      rethrow;
    }
  }

  // DELETE: Xóa địa chỉ
  Future<void> deleteDeliveryAddress(String maDiaChi) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${Constant().baseUrl}/DeliveryAddress/$maDiaChi'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Lỗi xóa địa chỉ');
      }
    } catch (e) {
      print('Error deleting delivery address: $e');
      rethrow;
    }
  }
}
