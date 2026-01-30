import 'package:flutter/material.dart';

class PromotionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textSecondary;

  const PromotionSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      color: surfaceColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm khuyến mãi...',
            prefixIcon: Icon(Icons.search, color: textSecondary),
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    );
  }
}

