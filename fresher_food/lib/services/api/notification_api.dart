import 'dart:convert';
import 'package:fresher_food/models/Notification.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class NotificationApi {
  /// Lấy danh sách thông báo của admin
  /// [maAdmin]: Mã tài khoản admin
  /// [unreadOnly]: Chỉ lấy thông báo chưa đọc nếu true
  Future<List<Notification>> getNotificationsByAdmin(
    String maAdmin, {
    bool unreadOnly = false,
  }) async {
    try {
      final url = unreadOnly
          ? '${Constant().baseUrl}/Notification/admin/$maAdmin?unreadOnly=true'
          : '${Constant().baseUrl}/Notification/admin/$maAdmin';

      final res = await http
          .get(
            Uri.parse(url),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get notifications: ${res.statusCode}');
        print('Response body: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body);
      if (data['data'] == null) {
        return [];
      }

      final List<dynamic> notificationsData = data['data'];
      return notificationsData
          .map((json) => Notification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Đếm số thông báo chưa đọc của admin
  Future<int> getUnreadCount(String maAdmin) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '${Constant().baseUrl}/Notification/admin/$maAdmin/unread-count'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to get unread count: ${res.statusCode}');
        return 0;
      }

      final data = jsonDecode(res.body);
      return data['count'] ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<bool> markAsRead(String maThongBao) async {
    try {
      final res = await http
          .put(
            Uri.parse(
                '${Constant().baseUrl}/Notification/$maThongBao/read'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark notification as read: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<bool> markAllAsRead(String maAdmin) async {
    try {
      final res = await http
          .put(
            Uri.parse(
                '${Constant().baseUrl}/Notification/admin/$maAdmin/read-all'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark all notifications as read: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}

