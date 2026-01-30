import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

/// Utility class cho password reset requests
class PasswordResetUtils {
  /// Format date thành relative time (ví dụ: "2 giờ trước", "Hôm qua")
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  /// Lấy màu sắc cho trạng thái
  static Color getStatusColor(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Lấy icon cho trạng thái
  static IconData getStatusIcon(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return Iconsax.clock;
      case 'Approved':
        return Iconsax.tick_circle;
      case 'Rejected':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  /// Lấy text hiển thị cho trạng thái
  static String getStatusText(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return 'Chờ xử lý';
      case 'Approved':
        return 'Đã duyệt';
      case 'Rejected':
        return 'Đã từ chối';
      default:
        return trangThai;
    }
  }
}

