import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchKeyword;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const ProductSearchBar({
    super.key,
    required this.searchController,
    required this.searchKeyword,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
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
        onChanged: onSearch,
      ),
    );
  }
}

