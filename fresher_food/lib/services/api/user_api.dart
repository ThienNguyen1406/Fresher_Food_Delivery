import 'dart:convert';

import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/User.dart';

class UserApi {
  Future<User?> login(String email, String matKhau) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/User/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'matKhau': matKhau,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Login API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        // Lưu thông tin user vào SharedPreferences
        await _saveUserInfo(user);
        return user;
      } else {
        throw Exception(
            'Đăng nhập thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // Đăng ký
  Future<bool> register(User user) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/User'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(user.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // Kiểm tra đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  // Lưu thông tin user
  Future<void> _saveUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maTaiKhoan', user.maTaiKhoan);
    await prefs.setString('tenNguoiDung', user.tenNguoiDung);
    await prefs.setString('email', user.email);
    await prefs.setString('hoTen', user.hoTen);
    await prefs.setString('sdt', user.sdt);
    await prefs.setString('diaChi', user.diaChi);
    await prefs.setString('vaiTro', user.vaiTro);
    await prefs.setBool('isLoggedIn', true);
  }

  // Lấy thông tin user từ SharedPreferences
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) return null;

    return User(
      maTaiKhoan: prefs.getString('maTaiKhoan') ?? '',
      tenNguoiDung: prefs.getString('tenNguoiDung') ?? '',
      matKhau: '', // Không lưu mật khẩu
      email: prefs.getString('email') ?? '',
      hoTen: prefs.getString('hoTen') ?? '',
      sdt: prefs.getString('sdt') ?? '',
      diaChi: prefs.getString('diaChi') ?? '',
      vaiTro: prefs.getString('vaiTro') ?? '',
    );
  }

  // ==================== USER INFO ====================

  // Lấy thông tin chi tiết người dùng từ API
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('User Info API Response: ${response.statusCode}');
      print('User Info API Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('User info data: $data');

        return {
          'maTaiKhoan': data['maTaiKhoan'] ?? '',
          'tenTaiKhoan': data['tenNguoiDung'] ?? data['hoTen'] ?? 'Người dùng',
          'email': data['email'] ?? '',
          'hoTen': data['hoTen'] ?? '',
          'sdt': data['sdt'] ?? '',
          'diaChi': data['diaChi'] ?? '',
          'vaiTro': data['vaiTro'] ?? 'user',
        };
      } else {
        final prefs = await SharedPreferences.getInstance();
        return {
          'maTaiKhoan': prefs.getString('maTaiKhoan') ?? '',
          'tenTaiKhoan': prefs.getString('tenNguoiDung') ??
              prefs.getString('hoTen') ??
              'Người dùng',
          'email': prefs.getString('email') ?? '',
          'hoTen': prefs.getString('hoTen') ?? '',
          'sdt': prefs.getString('sdt') ?? '',
          'diaChi': prefs.getString('diaChi') ?? '',
          'vaiTro': prefs.getString('vaiTro') ?? 'user',
        };
      }
    } catch (e) {
      print('Error getting user info: $e');
      final prefs = await SharedPreferences.getInstance();
      return {
        'maTaiKhoan': prefs.getString('maTaiKhoan') ?? '',
        'tenTaiKhoan': prefs.getString('tenNguoiDung') ??
            prefs.getString('hoTen') ??
            'Người dùng',
        'email': prefs.getString('email') ?? '',
        'hoTen': prefs.getString('hoTen') ?? '',
        'sdt': prefs.getString('sdt') ?? '',
        'diaChi': prefs.getString('diaChi') ?? '',
        'vaiTro': prefs.getString('vaiTro') ?? 'user',
      };
    }
  }

  // Cập nhật thông tin người dùng
  Future<bool> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}'),
            headers: headers,
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (userData.containsKey('tenNguoiDung')) {
          await prefs.setString('tenNguoiDung', userData['tenNguoiDung']);
        }
        if (userData.containsKey('hoTen')) {
          await prefs.setString('hoTen', userData['hoTen']);
        }
        if (userData.containsKey('sdt')) {
          await prefs.setString('sdt', userData['sdt']);
        }
        if (userData.containsKey('diaChi')) {
          await prefs.setString('diaChi', userData['diaChi']);
        }
        if (userData.containsKey('email')) {
          await prefs.setString('email', userData['email']);
        }

        return true;
      } else {
        throw Exception('Failed to update user info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user info: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/User'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      // Parse thành List<Map<String, dynamic>>
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateNguoiDung(
      String maTaiKhoan, Map<String, dynamic> data) async {
    final res = await http.put(
        Uri.parse('${Constant().baseUrl}/User/$maTaiKhoan'),
        body: jsonEncode(data));
    return res.statusCode == 200;
  }

  Future<bool> deleteNguoiDung(String maTaiKhoan) async {
    final res =
        await http.delete(Uri.parse('${Constant().baseUrl}/User/$maTaiKhoan'));
    return res.statusCode == 200;
  }

  Future isAdmin() async {}
}
