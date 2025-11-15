import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/home/widgets/category_item_widget.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Danh mục",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  provider.state.isLoadingCategories
                      ? _buildCategoriesLoading()
                      : _buildCategoriesList(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesLoading() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
        ],
      ),
    );
  }

  Widget _buildCategoryItemLoading() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(HomeProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Danh mục "Tất cả"
          CategoryItemWidget(
            title: "Tất cả",
            icon: Icons.category,
            isActive: provider.state.selectedCategoryId == 'all',
            onTap: () => provider.fetchProductsByCategory('all'),
          ),
          // Các danh mục từ API
          ...provider.state.categories.map((category) => CategoryItemWidget(
                title: category.tenDanhMuc,
                icon: _getCategoryIcon(category.tenDanhMuc),
                isActive: provider.state.selectedCategoryId == category.maDanhMuc,
                onTap: () =>
                    provider.fetchProductsByCategory(category.maDanhMuc),
              )),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('rau') || name.contains('củ')) {
      return Icons.eco;
    } else if (name.contains('trái') ||
        name.contains('cây') ||
        name.contains('quả')) {
      return Icons.apple;
    } else if (name.contains('thịt') || name.contains('cá')) {
      return Icons.set_meal;
    } else if (name.contains('uống') || name.contains('nước')) {
      return Icons.local_drink;
    } else if (name.contains('sữa') || name.contains('bơ')) {
      return Icons.breakfast_dining;
    } else {
      return Icons.category;
    }
  }
}

