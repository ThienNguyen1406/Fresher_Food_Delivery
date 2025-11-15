import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';

class CartLoginRequired extends StatelessWidget {
  const CartLoginRequired({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vui lòng đăng nhập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để xem giỏ hàng của bạn',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              AppRoute.push(context, AppRoute.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.green.shade400
                  : Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: isDark ? 6 : 2,
              shadowColor: isDark
                  ? Colors.green.shade400.withOpacity(0.5)
                  : null,
            ),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

