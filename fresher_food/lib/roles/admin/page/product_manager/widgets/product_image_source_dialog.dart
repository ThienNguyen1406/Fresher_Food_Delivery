import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductImageSourceDialog extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ProductImageSourceDialog({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.gallery, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Chọn ảnh sản phẩm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildImageSourceButton(
                    onPressed: onCamera,
                    icon: Iconsax.camera,
                    text: 'Chụp ảnh mới',
                  ),
                  const SizedBox(height: 12),
                  _buildImageSourceButton(
                    onPressed: onGallery,
                    icon: Iconsax.gallery,
                    text: 'Chọn từ thư viện',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2E7D32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E7D32)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

