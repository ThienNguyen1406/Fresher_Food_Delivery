import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PasswordResetEmptyState extends StatelessWidget {
  final String selectedFilter;
  final String Function(String) getStatusText;

  const PasswordResetEmptyState({
    super.key,
    required this.selectedFilter,
    required this.getStatusText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.document_text,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có yêu cầu nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'All'
                ? 'Tất cả các yêu cầu sẽ hiển thị ở đây'
                : 'Không có yêu cầu ${getStatusText(selectedFilter).toLowerCase()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

