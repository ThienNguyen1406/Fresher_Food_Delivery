import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:iconsax/iconsax.dart';

class ProductCategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onChanged;

  const ProductCategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategoryId,
              isExpanded: true,
              icon: const Icon(Iconsax.arrow_down_1, color: Color(0xFF2E7D32)),
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Chọn danh mục'),
              ),
              items: categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.maDanhMuc,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      category.tenDanhMuc,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

