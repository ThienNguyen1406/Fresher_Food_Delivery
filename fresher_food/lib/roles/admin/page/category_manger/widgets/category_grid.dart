import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Color Function(int) getCategoryColor;
  final String Function(String) getImageUrl;
  final Function(Category) onEdit;
  final Function(Category) onDelete;
  final VoidCallback onRefresh;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.getCategoryColor,
    required this.getImageUrl,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF1A4D2E),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final color = getCategoryColor(index);

          return CategoryCard(
            category: category,
            color: color,
            getImageUrl: getImageUrl,
            onEdit: () => onEdit(category),
            onDelete: () => onDelete(category),
          );
        },
      ),
    );
  }
}

