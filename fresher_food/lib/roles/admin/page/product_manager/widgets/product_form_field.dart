import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const ProductFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: maxLines > 1 ? TextInputType.multiline : (keyboardType ?? TextInputType.text),
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      enableInteractiveSelection: true,
      // 🔥 FIX: Bật suggestions và autocorrect cho tiếng Việt
      enableSuggestions: true,
      autocorrect: true,
      // 🔥 FIX: Không giới hạn text input, cho phép tất cả ký tự Unicode (bao gồm tiếng Việt)
      inputFormatters: keyboardType == TextInputType.number 
          ? [FilteringTextInputFormatter.digitsOnly]
          : null, // Không filter cho text input, cho phép tiếng Việt
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      // 🔥 FIX: Không capitalize tự động để giữ nguyên tiếng Việt
      textCapitalization: TextCapitalization.none,
      // 🔥 FIX: Bật smart dashes và quotes cho tiếng Việt
      smartDashesType: SmartDashesType.enabled,
      smartQuotesType: SmartQuotesType.enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

