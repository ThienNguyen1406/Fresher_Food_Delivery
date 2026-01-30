import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CategorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchKeyword;
  final Function(String) onSearchChanged;
  final VoidCallback onClear;

  const CategorySearchBar({
    super.key,
    required this.controller,
    required this.searchKeyword,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm danh mục...',
          prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
          suffixIcon: searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.grey),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}

