import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CategoryEmptyState extends StatelessWidget {
  final String searchKeyword;
  final VoidCallback onAddCategory;

  const CategoryEmptyState({
    super.key,
    required this.searchKeyword,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = searchKeyword.isEmpty;

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
              isEmpty ? Iconsax.category : Iconsax.search_normal,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isEmpty ? 'Chưa có danh mục nào' : 'Không tìm thấy danh mục',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty ? 'Hãy thêm danh mục đầu tiên của bạn' : 'Thử tìm kiếm với từ khóa khác',
            style: const TextStyle(color: Colors.grey),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: onAddCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4D2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thêm danh mục đầu tiên'),
              ),
            ),
        ],
      ),
    );
  }
}

