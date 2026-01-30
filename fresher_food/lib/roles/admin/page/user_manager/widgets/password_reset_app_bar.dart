import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PasswordResetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int pendingCount;
  final VoidCallback onRefresh;

  const PasswordResetAppBar({
    super.key,
    required this.pendingCount,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Text(
            'Yêu cầu đặt lại mật khẩu',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pendingCount > 99 ? '99+' : '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: onRefresh,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }
}

