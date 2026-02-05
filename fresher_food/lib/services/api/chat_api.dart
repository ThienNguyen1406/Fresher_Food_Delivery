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
      final url = '${Constant().baseUrl}/Chat';
      final body = {
        'maNguoiDung': maNguoiDung,
        'tieuDe': tieuDe,
        'noiDungTinNhanDau': noiDungTinNhanDau,
      };
      
      print('🔵 Creating chat - URL: $url');
      print('🔵 Request body: $body');
      
      final res = await http
          .post(
            Uri.parse(url),
            headers: await ApiService().getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      print('🔵 Response status: ${res.statusCode}');
      print('🔵 Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final result = jsonDecode(res.body);
          print('🔵 Parsed result: $result');
          return result;
        } catch (e) {
          print('❌ Error parsing response: $e');
          print('❌ Response body: ${res.body}');
          return null;
        }
      } else {
        print('❌ Failed to create chat: ${res.statusCode}');
        print('❌ Response body: ${res.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error creating chat: $e');
      print('❌ Stack trace: $stackTrace');
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
          .timeout(const Duration(seconds: 60));

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
          .timeout(const Duration(seconds: 60));

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

  Map<String, String>? _cachedHeaders;
  
  /// Lấy tin nhắn của một chat với pagination
  /// [limit] - Số tin nhắn cần lấy (mặc định 10)
  /// [beforeMessageId] - ID tin nhắn để lấy tin nhắn cũ hơn (null = lấy mới nhất)
  Future<Map<String, dynamic>> getMessages({
    required String maChat,
    int limit = 10,
    String? beforeMessageId,
  }) async {
    try {
      final uri = Uri.parse('${Constant().baseUrl}/Chat/$maChat/messages')
          .replace(queryParameters: {
        'limit': limit.toString(),
        if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      });

      if (_cachedHeaders == null) {
        _cachedHeaders = await ApiService().getHeaders();
      }

      final res = await http
          .get(
            uri,
            headers: _cachedHeaders!,
          )
          .timeout(const Duration(seconds: 8)); // Giảm timeout xuống 8s để load nhanh hơn

      if (res.statusCode != 200) {
        print('Failed to get messages: ${res.statusCode}');
        return {
          'messages': <Message>[],
          'hasMore': false,
          'totalCount': 0,
        };
      }

      final data = jsonDecode(res.body);
      final List<dynamic> messagesData = data['messages'] ?? [];
      final messages = messagesData.map((json) => Message.fromJson(json)).toList();

      return {
        'messages': messages,
        'hasMore': data['hasMore'] ?? false,
        'totalCount': data['totalCount'] ?? 0,
      };
    } catch (e) {
      print('Error getting messages: $e');
      return {
        'messages': <Message>[],
        'hasMore': false,
        'totalCount': 0,
      };
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
          .timeout(const Duration(seconds: 60));

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
          .timeout(const Duration(seconds: 60));

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
          .timeout(const Duration(seconds: 60));

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

  /// Xóa cuộc trò chuyện
  Future<bool> deleteChat(String maChat, String maNguoiDung) async {
    try {
      final uri = Uri.parse('${Constant().baseUrl}/Chat/$maChat')
          .replace(queryParameters: {
        'maNguoiDung': maNguoiDung,
      });
      
      final res = await http
          .delete(
            uri,
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        print('Failed to delete chat: ${res.statusCode}');
        print('Response body: ${res.body}');
        return false;
      }
      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }
}

