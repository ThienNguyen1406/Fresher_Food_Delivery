import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductAddFab extends StatelessWidget {
  final VoidCallback onPressed;

  const ProductAddFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Iconsax.add, size: 24),
    );
  }
}
