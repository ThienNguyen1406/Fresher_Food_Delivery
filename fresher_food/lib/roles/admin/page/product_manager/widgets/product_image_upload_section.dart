import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:iconsax/iconsax.dart';

class ProductImageUploadSection extends StatelessWidget {
  final Product? product;
  final File? selectedImage;
  final bool isUploading;
  final VoidCallback onPickImage;

  const ProductImageUploadSection({
    super.key,
    this.product,
    this.selectedImage,
    required this.isUploading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasExistingImage = product?.anh != null && product!.anh.isNotEmpty;
    final hasNewImage = selectedImage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Iconsax.gallery, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Hình ảnh sản phẩm',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              image: hasNewImage
                  ? DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : hasExistingImage
                      ? DecorationImage(
                          image: NetworkImage(product!.anh),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: !hasNewImage && !hasExistingImage
                ? const Icon(Iconsax.gallery, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          isUploading
              ? const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 8),
                    Text('Đang xử lý...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              : ElevatedButton(
                  onPressed: onPickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.gallery_add, size: 16),
                      SizedBox(width: 4),
                      Text('Chọn ảnh'),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

