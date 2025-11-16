import 'dart:convert';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class ChatApi {
  /// Tạo cuộc trò chuyện mới
  Future<Map<String, dynamic>?> createChat({
    required String maNguoiDung,
    String? tieuDe,
    String? noiDungTinNhanDau,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Chat'),
            headers: await ApiService().getHeaders(),
            body: jsonEncode({
              'maNguoiDung': maNguoiDung,
              'tieuDe': tieuDe,
              'noiDungTinNhanDau': noiDungTinNhanDau,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to create chat: ${res.statusCode}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  /// Lấy danh sách chat của user
  Future<List<Chat>> getUserChats(String maNguoiDung) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Chat/user/$maNguoiDung'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get user chats: ${res.statusCode}');
        print('Response body: ${res.body}');
        return [];
      }

      final List<dynamic> data = jsonDecode(res.body);
      print('Received ${data.length} chats');
      final chats = data.map((json) {
        try {
          return Chat.fromJson(json);
        } catch (e) {
          print('Error parsing chat: $e');
          print('Chat JSON: $json');
          rethrow;
        }
      }).toList();
      return chats;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  /// Lấy danh sách chat cho admin
  Future<List<Chat>> getAdminChats() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Chat/admin'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get admin chats: ${res.statusCode}');
        return [];
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Chat.fromJson(json)).toList();
    } catch (e) {
      print('Error getting admin chats: $e');
      return [];
    }
  }

  /// Lấy tin nhắn của một chat
  Future<List<Message>> getMessages(String maChat) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Chat/$maChat/messages'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get messages: ${res.statusCode}');
        return [];
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// Gửi tin nhắn
  Future<bool> sendMessage({
    required String maChat,
    required String maNguoiGui,
    required String loaiNguoiGui,
    required String noiDung,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Chat/message'),
            headers: await ApiService().getHeaders(),
            body: jsonEncode({
              'maChat': maChat,
              'maNguoiGui': maNguoiGui,
              'loaiNguoiGui': loaiNguoiGui,
              'noiDung': noiDung,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to send message: ${res.statusCode}');
        return false;
      }
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Đánh dấu tin nhắn đã đọc
  Future<bool> markAsRead({
    required String maChat,
    required String maNguoiDoc,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Chat/$maChat/read'),
            headers: await ApiService().getHeaders(),
            body: jsonEncode({
              'maNguoiDoc': maNguoiDoc,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to mark as read: ${res.statusCode}');
        return false;
      }
      return true;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// Đóng chat
  Future<bool> closeChat(String maChat) async {
    try {
      final res = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Chat/$maChat/close'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to close chat: ${res.statusCode}');
        return false;
      }
      return true;
    } catch (e) {
      print('Error closing chat: $e');
      return false;
    }
  }
}

