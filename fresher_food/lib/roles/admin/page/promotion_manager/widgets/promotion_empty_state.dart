import 'package:flutter/material.dart';

class PromotionEmptyState extends StatelessWidget {
  final Color textSecondary;

  const PromotionEmptyState({
    super.key,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: textSecondary),
          const SizedBox(height: 16),
          Text(
            'Chưa có khuyến mãi nào',
            style: TextStyle(
              fontSize: 18,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

