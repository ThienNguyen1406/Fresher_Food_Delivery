import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductEmptyScreen extends StatelessWidget {
  final String searchKeyword;
  final VoidCallback onAddProduct;

  const ProductEmptyScreen({
    super.key,
    required this.searchKeyword,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchKeyword.isEmpty ? Iconsax.box : Iconsax.search_normal,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchKeyword.isEmpty ? 'Chưa có sản phẩm nào' : 'Không tìm thấy sản phẩm',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            searchKeyword.isEmpty ? 'Hãy thêm sản phẩm đầu tiên của bạn' : 'Thử tìm kiếm với từ khóa khác',
            style: const TextStyle(color: Colors.grey),
          ),
          if (searchKeyword.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: onAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thêm sản phẩm đầu tiên'),
              ),
            ),
        ],
      ),
    );
  }
}

