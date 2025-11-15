import 'dart:convert';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class StripeApi {
  // Lấy publishable key từ backend
  Future<String> getPublishableKey() async {
    try {
      final headers = await ApiService().getHeaders();
      final url = Uri.parse('${Constant().baseUrl}/Stripe/publishable-key');

      print('🔑 Fetching Stripe publishable key from: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('🔑 Publishable Key API Response: ${response.statusCode}');
      print('🔑 Publishable Key API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final key = data['publishableKey'] as String?;

        if (key == null || key.isEmpty) {
          throw Exception('Publishable key is null or empty from backend');
        }

        print(
            '🔑 Successfully retrieved publishable key: ${key.substring(0, 20)}...');
        return key;
      } else {
        throw Exception(
            'Failed to get publishable key: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting publishable key: $e');
      throw Exception('Error getting publishable key: $e');
    }
  }

  // Tạo payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String? orderId,
    String? userId,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Stripe/create-payment-intent'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'amount': amount,
              'orderId': orderId,
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Stripe Payment Intent API Response: ${response.statusCode}');
      print('Stripe Payment Intent API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'clientSecret': data['clientSecret'] as String,
          'paymentIntentId': data['paymentIntentId'] as String,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Xác nhận thanh toán
  Future<bool> confirmPayment(String paymentIntentId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Stripe/confirm-payment'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'paymentIntentId': paymentIntentId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Stripe Confirm Payment API Response: ${response.statusCode}');
      print('Stripe Confirm Payment API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] as bool? ?? false;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      print('Error confirming payment: $e');
      throw Exception('Error confirming payment: $e');
    }
  }
}
