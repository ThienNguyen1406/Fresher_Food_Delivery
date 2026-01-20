import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/home/widgets/product_card_widget.dart';
import 'package:fresher_food/utils/screen_size.dart';

class ProductsSection extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onResetSearch;

  const ProductsSection({
    super.key,
    required this.searchController,
    required this.onResetSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          if (state.isLoading) {
            return _buildProductsLoading();
          } else if (state.filteredProducts.isEmpty) {
            return _buildEmptyProducts(provider);
          } else {
            return _buildProductsGrid(context, provider);
          }
        },
      ),
    );
  }

  SliverToBoxAdapter _buildProductsLoading() {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang tải sản phẩm...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEmptyProducts(HomeProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                searchController.text.isEmpty
                    ? 'Không có sản phẩm nào'
                    : 'Không tìm thấy sản phẩm "${searchController.text}"',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (searchController.text.isNotEmpty)
                TextButton(
                  onPressed: onResetSearch,
                  child: const Text(
                    'Hiển thị tất cả sản phẩm',
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverGrid _buildProductsGrid(BuildContext context, HomeProvider provider) {
    final screenSize = ScreenSize.fromContext(context);
    final crossAxisCount = screenSize.getGridColumnCount(
      phoneColumns: 2,
      tabletColumns: 3,
    );
    final aspectRatio = screenSize.getProductCardAspectRatio();
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.getSpacing(base: 16),
        mainAxisSpacing: screenSize.getSpacing(base: 16),
        childAspectRatio: aspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = provider.state.filteredProducts[index];
          return ProductCardWidget(
            product: product,
            provider: provider,
          );
        },
        childCount: provider.state.filteredProducts.length,
      ),
    );
  }
}

