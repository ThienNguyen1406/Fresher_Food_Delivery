import 'dart:convert';

import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

import '../../models/Pay.dart';

class PaymentApi {
  //===================== PAY ===================
  Future<List<Pay>> getPay() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Pay'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Pay API Response: ${response.statusCode}');
      print('Pay API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} pay methods');

        if (data.isEmpty) {
          throw Exception('No pay methods available');
        }

        return data.map((e) => Pay.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load pay methods: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting pay methods: $e');
      throw Exception('Error getting pay methods: $e');
    }
  }
}
