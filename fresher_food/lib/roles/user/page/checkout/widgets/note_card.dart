import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';

class NoteCard extends StatelessWidget {
  final CheckoutProvider provider;
  final TextEditingController noteController;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color backgroundColor;

  const NoteCard({
    super.key,
    required this.provider,
    required this.noteController,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cho đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: noteController,
            onChanged: provider.updateNote,
            maxLines: 3,
            style: TextStyle(color: textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Giao hàng giờ hành chính, gọi điện trước khi giao...',
              hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: textSecondary.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

