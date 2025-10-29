import 'package:fresher_food/utils/shareprefernces.dart';

class ApiService {
  Future<Map<String, String>> getHeaders() async {
    final token = await Shareprefernces().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
