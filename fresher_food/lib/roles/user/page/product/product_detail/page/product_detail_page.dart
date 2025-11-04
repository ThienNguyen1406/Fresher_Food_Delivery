// pages/productdetail_page.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Rating.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with TickerProviderStateMixin {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildProductDetail(BuildContext context, ProductDetailProvider productDetailProvider) {
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
            SliverAppBar(
              expandedHeight: 450,
              backgroundColor: Colors.transparent,
              floating: false,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      itemCount: productImages.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Hero(
                          tag: product.maSanPham,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(productImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          productImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentImageIndex == index ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (productDetailProvider.isOutOfStock)
                      Positioned(
                        top: 80,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'HẾT HÀNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card thông tin chính
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.tenSanPham,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (productDetailProvider.isOutOfStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          'Hết hàng',
                                          style: TextStyle(
                                            color: Colors.red.shade600,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    else if (productDetailProvider.isLowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Text(
                                          'Chỉ còn ${product.soLuongTon} sản phẩm',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _toggleFavorite(productDetailProvider),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: productDetailProvider.isFavorite 
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: productDetailProvider.isFavorite 
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      productDetailProvider.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: productDetailProvider.isFavorite ? Colors.red : Colors.grey,
                                      size: 20,
                                      key: ValueKey(productDetailProvider.isFavorite),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.location_on_outlined,
                                text: product.xuatXu,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.inventory_2_outlined,
                                text: '${product.soLuongTon} ${product.donViTinh}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.giaBan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: productDetailProvider.isOutOfStock ? Colors.grey.shade400 : Colors.green.shade600,
                                ),
                              ),
                              _buildRatingWidget(productDetailProvider),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mô tả sản phẩm
                    _buildSection(
                      icon: Icons.description_outlined,
                      title: "Mô tả sản phẩm",
                      child: Text(
                        product.moTa.isNotEmpty
                            ? product.moTa
                            : "Sản phẩm chất lượng cao, phù hợp cho mọi gia đình. Hương vị tươi ngon và giá trị dinh dưỡng tuyệt vời.",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Thông tin bổ sung
                    _buildSection(
                      icon: Icons.info_outline_rounded,
                      title: "Thông tin chi tiết",
                      child: Column(
                        children: [
                          _buildDetailRow("Xuất xứ", product.xuatXu),
                          _buildDetailRow("Đơn vị tính", product.donViTinh),
                          _buildDetailRow("Số lượng tồn", "${product.soLuongTon} ${product.donViTinh}"),
                          _buildDetailRow("Mã sản phẩm", product.maSanPham),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PHẦN ĐÁNH GIÁ
                    _buildRatingSection(productDetailProvider),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Nút back
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: _buildBackButton(context),
        ),

        // Thanh hành động cố định
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomActionBar(productDetailProvider),
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

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
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
          if (!productDetailProvider.isOutOfStock)
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
                      color: productDetailProvider.quantity > 1 ? Colors.grey.shade700 : Colors.grey.shade400,
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
                      color: productDetailProvider.quantity < productDetailProvider.product!.soLuongTon 
                          ? Colors.green.shade600 
                          : Colors.grey.shade400,
                    ),
                    onPressed: productDetailProvider.increaseQuantity,
                  ),
                ],
              ),
            ),
          
          if (!productDetailProvider.isOutOfStock) const SizedBox(width: 16),
          
          Expanded(
            child: AnimatedBuilder(
              animation: _addToCartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: ElevatedButton(
                onPressed: productDetailProvider.isOutOfStock ? null : () => _addToCart(productDetailProvider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: productDetailProvider.isOutOfStock 
                      ? Colors.grey.shade400 
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: productDetailProvider.isOutOfStock ? 0 : 4,
                  shadowColor: productDetailProvider.isOutOfStock 
                      ? Colors.transparent 
                      : Colors.green.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      productDetailProvider.isOutOfStock ? Icons.inventory_2_outlined : Icons.shopping_cart_outlined, 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      productDetailProvider.isOutOfStock ? "HẾT HÀNG" : "Thêm vào giỏ hàng",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Các method xử lý sự kiện
  Future<void> _toggleFavorite(ProductDetailProvider productDetailProvider) async {
    try {
      await productDetailProvider.toggleFavorite(widget.productId);
      if (productDetailProvider.isFavorite) {
        _favoriteController.forward();
      } else {
        _favoriteController.reverse();
      }
    } catch (e) {
      _showLoginRequiredSnackBar();
    }
  }

  Future<void> _addToCart(ProductDetailProvider productDetailProvider) async {
    try {
      _addToCartController.forward().then((_) {
        _addToCartController.reverse();
      });

      final success = await productDetailProvider.addToCart();
      if (success) {
        _showSuccessSnackBar('Đã thêm "${productDetailProvider.product!.tenSanPham}" vào giỏ hàng');
      } else {
        _showErrorSnackBar('Không thể thêm sản phẩm vào giỏ hàng');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    }
  }

  // Các method hiển thị thông báo (giữ nguyên)
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  void _showLoginRequiredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning,
                color: Colors.orange.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Vui lòng đăng nhập để sử dụng tính năng này')),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to login screen
          },
        ),
      ),
    );
  }

  // PHẦN ĐÁNH GIÁ (giữ nguyên từ file gốc)
  Widget _buildRatingSection(ProductDetailProvider productDetailProvider) {
    return _buildSection(
      icon: Icons.reviews_outlined,
      title: "Đánh giá khách hàng (${productDetailProvider.ratingStats.totalRatings})",
      child: Column(
        children: [
          // Thống kê đánh giá
          _buildRatingStats(productDetailProvider),
          const SizedBox(height: 16),
          
          // Nút hành động đánh giá
          _buildRatingActionButton(productDetailProvider),
          const SizedBox(height: 16),
          
          // Danh sách đánh giá
          _buildRatingsList(productDetailProvider),
        ],
      ),
    );
  }

  Widget _buildRatingStats(ProductDetailProvider productDetailProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  productDetailProvider.ratingStats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Text(
                  'Điểm trung bình',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  productDetailProvider.ratingStats.totalRatings.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Lượt đánh giá',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingActionButton(ProductDetailProvider productDetailProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            productDetailProvider.hasUserRated ? Icons.star : Icons.star_outline,
            color: productDetailProvider.hasUserRated ? Colors.amber : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productDetailProvider.hasUserRated ? 'Bạn đã đánh giá sản phẩm này' : 'Chia sẻ đánh giá của bạn',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (productDetailProvider.hasUserRated && productDetailProvider.userRating != null)
                  Text(
                    '${productDetailProvider.userRating!.soSao} sao - ${productDetailProvider.userRating!.noiDung ?? "Không có nhận xét"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (productDetailProvider.hasUserRated)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showRatingDialog(productDetailProvider),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteRating(productDetailProvider),
                  color: Colors.red,
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _showRatingDialog(productDetailProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('ĐÁNH GIÁ NGAY'),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingsList(ProductDetailProvider productDetailProvider) {
    if (productDetailProvider.isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productDetailProvider.ratings.isEmpty) {
      return const Column(
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên đánh giá sản phẩm này',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: productDetailProvider.ratings.map((rating) => _buildRatingItem(rating, productDetailProvider)).toList(),
    );
  }

  Widget _buildRatingItem(Rating rating, ProductDetailProvider productDetailProvider) {
    final isCurrentUser = productDetailProvider.userRating?.maTaiKhoan == rating.maTaiKhoan;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade200,
          child: Text(
            rating.maTaiKhoan.characters.first.toUpperCase(),
            style: TextStyle(
              color: isCurrentUser ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            for (int i = 0; i < 5; i++)
              Icon(
                i < rating.soSao ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            const SizedBox(width: 8),
            Text('${rating.soSao}/5'),
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rating.noiDung != null && rating.noiDung!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  rating.noiDung!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Người dùng: ${rating.maTaiKhoan}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(ProductDetailProvider productDetailProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RatingDialog(
          productId: widget.productId,
          productName: productDetailProvider.product?.tenSanPham ?? '',
          userRating: productDetailProvider.userRating,
          onRatingSubmitted: () {
            productDetailProvider.loadProductDetail(widget.productId);
            Navigator.of(context).pop();
          },
          productDetailProvider: productDetailProvider,
        );
      },
    );
  }

  Future<void> _deleteRating(ProductDetailProvider productDetailProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa đánh giá'),
          content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('XÓA', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await productDetailProvider.deleteRating(widget.productId);
        if (success) {
          _showSuccessSnackBar('Đã xóa đánh giá thành công');
        } else {
          _showErrorSnackBar('Không thể xóa đánh giá');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi xóa đánh giá: $e');
      }
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

// Dialog đánh giá (cần chỉnh sửa để sử dụng Provider)
class RatingDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Rating? userRating;
  final VoidCallback onRatingSubmitted;
  final ProductDetailProvider productDetailProvider;

  const RatingDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.userRating,
    required this.onRatingSubmitted,
    required this.productDetailProvider,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedStars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.userRating != null) {
      _selectedStars = widget.userRating!.soSao;
      _reviewController.text = widget.userRating!.noiDung ?? '';
    }
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rating = Rating(
        maSanPham: widget.productId,
        maTaiKhoan: '', // Will be filled by service
        soSao: _selectedStars,
        noiDung: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      );

      final success = await widget.productDetailProvider.submitRating(rating);
      if (success) {
        widget.onRatingSubmitted();
      } else {
        throw Exception('Không thể gửi đánh giá');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userRating != null && widget.userRating!.soSao > 0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Chỉnh sửa đánh giá' : 'Đánh giá sản phẩm',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.productName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            
            // Star rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStars = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starIndex <= _selectedStars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            
            // Review text
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('HỦY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEdit ? 'CẬP NHẬT' : 'GỬI ĐÁNH GIÁ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}