import 'package:flutter/material.dart';

class PasswordResetConfirmDialog extends StatelessWidget {
  final String action; // 'Approve' or 'Reject'
  final String email;

  const PasswordResetConfirmDialog({
    super.key,
    required this.action,
    required this.email,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String action,
    required String email,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PasswordResetConfirmDialog(
        action: action,
        email: email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(action == 'Approve' ? 'Xác nhận duyệt' : 'Xác nhận từ chối'),
      content: Text(
        action == 'Approve'
            ? 'Bạn có chắc chắn muốn duyệt yêu cầu đặt lại mật khẩu cho $email?'
            : 'Bạn có chắc chắn muốn từ chối yêu cầu đặt lại mật khẩu cho $email?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: action == 'Approve' ? Colors.green : Colors.red,
          ),
          child: Text(action == 'Approve' ? 'Duyệt' : 'Từ chối'),
        ),
      ],
    );
  }
}

