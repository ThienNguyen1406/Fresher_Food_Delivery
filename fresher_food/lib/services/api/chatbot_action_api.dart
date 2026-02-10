import 'dart:convert';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class ChatbotActionApi {
  Future<Map<String, dynamic>> addToCartFromChatbot({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      final url = '${Constant().baseUrl}/Carts/add';
      final body = {
        'maTaiKhoan': userId,
        'maSanPham': productId,
        'soLuong': quantity,
      };

      final res = await http
          .post(
            Uri.parse(url),
            headers: await ApiService().getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(res.body)['message'] ?? 'Thêm vào giỏ hàng thành công',
        };
      } else {
        final error = jsonDecode(res.body)['error'] ?? 'Có lỗi xảy ra';
        return {
          'success': false,
          'message': error,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }
}
