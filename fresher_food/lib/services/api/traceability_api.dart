import 'dart:convert';
import 'package:fresher_food/models/ProductTraceability.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class TraceabilityApi {
  /// Lấy thông tin truy xuất nguồn gốc từ QR code
  Future<ProductTraceabilityResponse?> getTraceabilityByQR(
      String maTruyXuat) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Traceability/$maTruyXuat'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to load traceability: ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body);
      return ProductTraceabilityResponse.fromJson(data);
    } catch (e) {
      print('Error fetching traceability: $e');
      return null;
    }
  }

  /// Tạo thông tin truy xuất nguồn gốc cho sản phẩm
  Future<Map<String, dynamic>?> createTraceability(
      Map<String, dynamic> traceabilityData) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Traceability'),
            headers: {
              ...await ApiService().getHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(traceabilityData),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to create traceability: ${res.statusCode}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error creating traceability: $e');
      return null;
    }
  }

  /// Lấy thông tin truy xuất theo mã sản phẩm
  Future<Map<String, dynamic>?> getTraceabilityByProductId(
      String maSanPham) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '${Constant().baseUrl}/Traceability/product/$maSanPham'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 404) {
        // Sản phẩm chưa có thông tin truy xuất
        return null;
      }

      if (res.statusCode != 200) {
        print('Failed to get traceability by product ID: ${res.statusCode}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error getting traceability by product ID: $e');
      return null;
    }
  }

  /// Verify thông tin trên blockchain
  Future<Map<String, dynamic>?> verifyBlockchain(
      String transactionId) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '${Constant().baseUrl}/Traceability/verify/$transactionId'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to verify blockchain: ${res.statusCode}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error verifying blockchain: $e');
      return null;
    }
  }
}

