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
        try {
          final data = jsonDecode(response.body);
          print('Login data parsed: $data');

          if (data['user'] == null) {
            throw Exception('Response không chứa thông tin user');
          }

          final user = User.fromJson(data['user']);
          print('User object created: ${user.maTaiKhoan}');

          // Lưu thông tin user vào SharedPreferences
          await _saveUserInfo(user);
          print('User info saved to SharedPreferences');

          return user;
        } catch (e) {
          print('Error parsing login response: $e');
          throw Exception('Lỗi xử lý dữ liệu đăng nhập: $e');
        }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('maTaiKhoan', user.maTaiKhoan);
      await prefs.setString('tenNguoiDung', user.tenNguoiDung);
      await prefs.setString('email', user.email);
      await prefs.setString('hoTen', user.hoTen);
      await prefs.setString('sdt', user.sdt);
      await prefs.setString('diaChi', user.diaChi);
      await prefs.setString('vaiTro', user.vaiTro);
      if (user.avatar != null) {
        await prefs.setString('avatar', user.avatar!);
      }
      await prefs.setBool('isLoggedIn', true);
      print('User info saved successfully');
    } catch (e) {
      print('Error saving user info: $e');
      throw Exception('Lỗi lưu thông tin user: $e');
    }
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
      avatar: prefs.getString('avatar'),
    );
  }

  // ==================== USER INFO ====================

  // Lấy thông tin chi tiết người dùng từ API
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('User Info API Response: ${response.statusCode}');
      print('User Info API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend có thể trả về User object trực tiếp hoặc trong wrapper
        final userData =
            data is Map<String, dynamic> && data.containsKey('user')
                ? data['user']
                : data;

        print('User info data: $userData');

        return {
          'maTaiKhoan': userData['maTaiKhoan']?.toString() ?? user.maTaiKhoan,
          'tenTaiKhoan': userData['tenNguoiDung']?.toString() ??
              userData['hoTen']?.toString() ??
              user.tenNguoiDung,
          'email': userData['email']?.toString() ?? user.email,
          'hoTen': userData['hoTen']?.toString() ?? user.hoTen,
          'sdt': userData['sdt']?.toString() ?? user.sdt,
          'diaChi': userData['diaChi']?.toString() ?? user.diaChi,
          'vaiTro': userData['vaiTro']?.toString() ?? user.vaiTro,
          'avatar': userData['avatar']?.toString() ?? user.avatar,
        };
      } else {
        // Nếu API lỗi, lấy từ SharedPreferences
        print('API failed, using cached data');
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
          'avatar': prefs.getString('avatar'),
        };
      }
    } catch (e) {
      print('Error getting user info: $e');
      // Fallback về SharedPreferences
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
        'avatar': prefs.getString('avatar'),
      };
    }
  }

  // Cập nhật thông tin người dùng
  Future<bool> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      // Chuẩn bị data để gửi lên backend
      // Backend cần đầy đủ thông tin User object
      final updateData = {
        'maTaiKhoan': user.maTaiKhoan,
        'tenNguoiDung': userData['tenNguoiDung'] ?? user.tenNguoiDung,
        'matKhau': '', // Không gửi mật khẩu, backend sẽ giữ nguyên mật khẩu cũ
        'email': userData['email'] ?? user.email,
        'hoTen': userData['hoTen'] ?? user.hoTen,
        'sdt': userData['sdt'] ?? user.sdt,
        'diaChi': userData['diaChi'] ?? user.diaChi,
        'vaiTro': user.vaiTro, // Giữ nguyên vai trò
      };

      print('Updating user info: $updateData');

      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 30));

      print('Update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Cập nhật SharedPreferences với dữ liệu mới
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
        print('User info updated successfully');
        return true;
      } else {
        final errorBody = response.body;
        print('Update failed: $errorBody');
        throw Exception(
            'Cập nhật thất bại: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('Error updating user info: $e');
      throw Exception('Lỗi cập nhật thông tin: $e');
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

  // Upload/Update Avatar
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}/avatar'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'avatarUrl': avatarUrl}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar', avatarUrl);
        return true;
      } else {
        throw Exception('Cập nhật avatar thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating avatar: $e');
      throw Exception('Lỗi cập nhật avatar: $e');
    }
  }

  // Delete Avatar
  Future<bool> deleteAvatar() async {
    try {
      final user = await getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .delete(
            Uri.parse('${Constant().baseUrl}/User/${user.maTaiKhoan}/avatar'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('avatar');
        return true;
      } else {
        throw Exception('Xóa avatar thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting avatar: $e');
      throw Exception('Lỗi xóa avatar: $e');
    }
  }
}
