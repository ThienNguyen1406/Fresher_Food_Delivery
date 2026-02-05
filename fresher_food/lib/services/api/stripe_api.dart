import 'dart:convert';
import 'package:fresher_food/models/SavedCard.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class StripeApi {
  // Lấy publishable key từ backend
  Future<String> getPublishableKey() async {
    try {
      final headers = await ApiService().getHeaders();
      final url = Uri.parse('${Constant().baseUrl}/Stripe/publishable-key');

      print('Fetching Stripe publishable key from: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('Publishable Key API Response: ${response.statusCode}');
      print('Publishable Key API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final key = data['publishableKey'] as String?;

        if (key == null || key.isEmpty) {
          throw Exception('Publishable key is null or empty from backend');
        }

        print(
            'Successfully retrieved publishable key: ${key.substring(0, 20)}...');
        return key;
      } else {
        throw Exception(
            'Failed to get publishable key: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting publishable key: $e');
      throw Exception('Error getting publishable key: $e');
    }
  }

  // Tạo payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String? orderId,
    String? userId,
    String? paymentMethodId,
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
              'paymentMethodId': paymentMethodId,
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

  // Cập nhật PaymentIntent với PaymentMethod
  Future<Map<String, dynamic>> updatePaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Stripe/update-payment-intent'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'paymentIntentId': paymentIntentId,
              'paymentMethodId': paymentMethodId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Update Payment Intent API Response: ${response.statusCode}');
      print('Update Payment Intent API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] as bool? ?? false,
          'clientSecret': data['clientSecret'] as String?,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update payment intent');
      }
    } catch (e) {
      print('Error updating payment intent: $e');
      throw Exception('Error updating payment intent: $e');
    }
  }

  // Xác nhận thanh toán
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    String? userId,
  }) async {
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
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Stripe Confirm Payment API Response: ${response.statusCode}');
      print('Stripe Confirm Payment API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] as bool? ?? false,
          'paymentMethodId': data['paymentMethodId'] as String?,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to confirm payment');
      }
    } catch (e) {
      print('Error confirming payment: $e');
      throw Exception('Error confirming payment: $e');
    }
  }

  // Lưu thẻ sau khi thanh toán thành công
  Future<SavedCard?> saveCard({
    required String paymentMethodId,
    required String userId,
    String? cardholderName,
    bool isDefault = false,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Stripe/save-card'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'paymentMethodId': paymentMethodId,
              'userId': userId,
              'cardholderName': cardholderName,
              'isDefault': isDefault,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Save Card API Response: ${response.statusCode}');
      print('Save Card API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SavedCard.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to save card');
      }
    } catch (e) {
      print('Error saving card: $e');
      throw Exception('Error saving card: $e');
    }
  }

  // Lấy danh sách thẻ đã lưu
  Future<List<SavedCard>> getSavedCards(String userId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Stripe/saved-cards?userId=$userId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Get Saved Cards API Response: ${response.statusCode}');
      print('Get Saved Cards API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => SavedCard.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get saved cards');
      }
    } catch (e) {
      print('Error getting saved cards: $e');
      throw Exception('Error getting saved cards: $e');
    }
  }

  // Xóa thẻ đã lưu
  Future<bool> deleteSavedCard(String cardId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .delete(
            Uri.parse('${Constant().baseUrl}/Stripe/saved-cards/$cardId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Delete Saved Card API Response: ${response.statusCode}');
      print('Delete Saved Card API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] as bool? ?? false;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete card');
      }
    } catch (e) {
      print('Error deleting saved card: $e');
      throw Exception('Error deleting saved card: $e');
    }
  }

  // Đặt thẻ làm mặc định
  Future<bool> setDefaultCard(String cardId, String userId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Stripe/saved-cards/$cardId/set-default'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Set Default Card API Response: ${response.statusCode}');
      print('Set Default Card API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] as bool? ?? false;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to set default card');
      }
    } catch (e) {
      print('Error setting default card: $e');
      throw Exception('Error setting default card: $e');
    }
  }
}
