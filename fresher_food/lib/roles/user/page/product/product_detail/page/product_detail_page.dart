// pages/productdetail_page.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_image_section.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_info_card.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_description_section.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_details_section.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_bottom_action_bar.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/product_back_button.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_section.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/snackbar_widgets.dart';
import 'package:fresher_food/utils/app_localizations.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _favoriteController;
  late AnimationController _addToCartController;
  late Animation<double> _scaleAnimation;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addToCartController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _addToCartController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductDetailProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductDetailProvider>(
        builder: (context, productDetailProvider, child) {
          if (productDetailProvider.isLoading) {
            return _buildLoadingScreen();
          } else if (productDetailProvider.errorMessage.isNotEmpty) {
            return _buildErrorScreen(productDetailProvider.errorMessage);
          } else if (productDetailProvider.product == null) {
            return _buildErrorScreen('Không tìm thấy sản phẩm');
          } else {
            return _buildProductDetail(context, productDetailProvider);
          }
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải sản phẩm...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetail(
      BuildContext context, ProductDetailProvider productDetailProvider) {
    final product = productDetailProvider.product!;
    final List<String> productImages = [
      product.anh,
      'https://picsum.photos/400/400?random=1',
      'https://picsum.photos/400/400?random=2',
    ];

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ProductImageSection(
              productImages: productImages,
              imagePageController: _imagePageController,
              currentImageIndex: _currentImageIndex,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              productId: product.maSanPham,
              isOutOfStock: productDetailProvider.isOutOfStock,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductInfoCard(
                      product: product,
                      provider: productDetailProvider,
                    ),
                    const SizedBox(height: 20),
                    ProductDescriptionSection(product: product),
                    const SizedBox(height: 20),
                    ProductDetailsSection(product: product),
                    const SizedBox(height: 20),
                    RatingSection(provider: productDetailProvider),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: const ProductBackButton(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ProductBottomActionBar(
            provider: productDetailProvider,
            addToCartController: _addToCartController,
            scaleAnimation: _scaleAnimation,
            onAddToCart: () => _addToCart(productDetailProvider),
          ),
        ),
      ],
    );
  }

  // Các method UI hỗ trợ (giữ nguyên từ file gốc)
  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black54,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingWidget(ProductDetailProvider productDetailProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            productDetailProvider.ratingStats.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${productDetailProvider.ratingStats.totalRatings})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ProductDetailProvider productDetailProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (productDetailProvider.canAddToCart)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_rounded,
                      color: productDetailProvider.quantity > 1
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    onPressed: productDetailProvider.decreaseQuantity,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      "${productDetailProvider.quantity}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_rounded,
                      color: productDetailProvider.quantity <
                              productDetailProvider.product!.soLuongTon
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                    ),
                    onPressed: productDetailProvider.increaseQuantity,
                  ),
                ],
              ),
            ),
          if (productDetailProvider.canAddToCart) const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _addToCartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return ElevatedButton(
                    onPressed: productDetailProvider.canAddToCart
                        ? () => _addToCart(productDetailProvider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: productDetailProvider.canAddToCart
                          ? (isDark
                              ? Colors.green.shade400
                              : Colors.green.shade600)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: productDetailProvider.canAddToCart
                          ? (isDark ? 6 : 4)
                          : 0,
                      shadowColor: productDetailProvider.canAddToCart
                          ? (isDark
                              ? Colors.green.shade400.withOpacity(0.5)
                              : Colors.green.withOpacity(0.3))
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          productDetailProvider.isExpired
                              ? Icons.warning_amber_rounded
                              : productDetailProvider.isOutOfStock
                                  ? Icons.inventory_2_outlined
                                  : Icons.shopping_cart_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          productDetailProvider.isExpired
                              ? "SẢN PHẨM HẾT HẠN"
                              : productDetailProvider.isOutOfStock
                                  ? "HẾT HÀNG"
                                  : "Thêm vào giỏ hàng",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Các method xử lý sự kiện
  Future<void> _addToCart(ProductDetailProvider productDetailProvider) async {
    try {
      _addToCartController.forward().then((_) {
        _addToCartController.reverse();
      });

      final success = await productDetailProvider.addToCart();
      if (success) {
        final localizations = AppLocalizations.of(context);
        final productName = productDetailProvider.product!.tenSanPham;
        final message = localizations != null
            ? '${localizations.addToCartSuccess}: "$productName"'
            : 'Đã thêm "$productName" vào giỏ hàng';
        SnackbarWidgets.showSuccess(
          context,
          message,
        );
      } else {
        final localizations = AppLocalizations.of(context);
        SnackbarWidgets.showError(
          context,
          localizations?.addToCartFailed ?? 'Không thể thêm sản phẩm vào giỏ hàng',
        );
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      final errorMessage = e.toString().contains('đăng nhập')
          ? e.toString()
          : (localizations?.addToCartFailed ?? 'Không thể thêm sản phẩm vào giỏ hàng');
      SnackbarWidgets.showError(context, errorMessage);
    }
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    _addToCartController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }
}
