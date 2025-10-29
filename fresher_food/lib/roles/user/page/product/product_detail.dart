import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/favorite_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/rating_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

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
  Product? product;
  bool isLoading = true;
  int quantity = 1;
  bool isFavorite = false;
  late AnimationController _favoriteController;
  late AnimationController _addToCartController;
  late Animation<double> _scaleAnimation;
  PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  // Biến cho phần đánh giá
  List<Rating> _ratings = [];
  RatingStats _ratingStats = RatingStats(averageRating: 0.0, totalRatings: 0);
  bool _isLoadingRatings = false;
  bool _hasUserRated = false;
  Rating? _userRating;

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
    fetchProductDetail();
    _checkFavoriteStatus();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      setState(() => _isLoadingRatings = true);
      
      // Load thống kê đánh giá
      final stats = await RatingApi().getProductRatingStats(widget.productId);
      
      // Load danh sách đánh giá
      final ratings = await RatingApi().getRatingsByProduct(widget.productId);
      
      // Kiểm tra xem user đã đánh giá chưa
      final userRating = await RatingApi().getUserRatingForProduct(widget.productId);
      
      setState(() {
        _ratingStats = stats;
        _ratings = ratings;
        _userRating = userRating;
        _hasUserRated = userRating != null && userRating.soSao > 0;
        _isLoadingRatings = false;
      });
    } catch (e) {
      print('Error loading ratings: $e');
      setState(() => _isLoadingRatings = false);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isLoggedIn = await UserApi().isLoggedIn();
      if (isLoggedIn) {
        final favorites = await FavoriteApi().getFavorites();
        setState(() {
          isFavorite = favorites.any((p) => p.maSanPham == widget.productId);
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final isLoggedIn = await UserApi().isLoggedIn();
      if (!isLoggedIn) {
        _showLoginRequiredSnackBar();
        return;
      }

      if (isFavorite) {
        await FavoriteApi().removeFromFavoritesByProductId(widget.productId);
        setState(() => isFavorite = false);
        _favoriteController.reverse();
      } else {
        await FavoriteApi().addToFavorites(widget.productId);
        setState(() => isFavorite = true);
        _favoriteController.forward();
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> fetchProductDetail() async {
    try {
      final productDetail = await ProductApi().getProductById(widget.productId);
      setState(() {
        product = productDetail;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching product detail: $e");
      setState(() => isLoading = false);
    }
  }

  // ==================== PHẦN ĐÁNH GIÁ ====================

  // Hiển thị dialog đánh giá
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RatingDialog(
          productId: widget.productId,
          productName: product?.tenSanPham ?? '',
          userRating: _userRating,
          onRatingSubmitted: () {
            _loadRatings(); // Reload ratings after submission
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Xóa đánh giá
  Future<void> _deleteRating() async {
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
        final success = await RatingApi().deleteRating(widget.productId);
        if (success) {
          _showSuccessSnackBar('Đã xóa đánh giá thành công');
          await _loadRatings();
        } else {
          _showErrorSnackBar('Không thể xóa đánh giá');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi xóa đánh giá: $e');
      }
    }
  }

  // Widget hiển thị phần đánh giá
  Widget _buildRatingSection() {
    return _buildSection(
      icon: Icons.reviews_outlined,
      title: "Đánh giá khách hàng (${_ratingStats.totalRatings})",
      child: Column(
        children: [
          // Thống kê đánh giá
          _buildRatingStats(),
          const SizedBox(height: 16),
          
          // Nút hành động đánh giá
          _buildRatingActionButton(),
          const SizedBox(height: 16),
          
          // Danh sách đánh giá
          _buildRatingsList(),
        ],
      ),
    );
  }

  // Thống kê đánh giá
  Widget _buildRatingStats() {
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
                  _ratingStats.averageRating.toStringAsFixed(1),
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
                  _ratingStats.totalRatings.toString(),
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

  // Nút hành động đánh giá
  Widget _buildRatingActionButton() {
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
            _hasUserRated ? Icons.star : Icons.star_outline,
            color: _hasUserRated ? Colors.amber : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasUserRated ? 'Bạn đã đánh giá sản phẩm này' : 'Chia sẻ đánh giá của bạn',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (_hasUserRated && _userRating != null)
                  Text(
                    '${_userRating!.soSao} sao - ${_userRating!.noiDung ?? "Không có nhận xét"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_hasUserRated)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _showRatingDialog,
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: _deleteRating,
                  color: Colors.red,
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _showRatingDialog,
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

  // Danh sách đánh giá
  Widget _buildRatingsList() {
    if (_isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ratings.isEmpty) {
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
      children: _ratings.map((rating) => _buildRatingItem(rating)).toList(),
    );
  }

  // Item đánh giá
  Widget _buildRatingItem(Rating rating) {
    final isCurrentUser = _userRating?.maTaiKhoan == rating.maTaiKhoan;
    
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
            // Hiển thị sao
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

  // ==================== CÁC PHẦN KHÁC GIỮ NGUYÊN ====================

  // Các method khác giữ nguyên (_buildLoadingScreen, _buildErrorScreen, _buildProductDetail, etc.)
  // ... [giữ nguyên tất cả các method khác] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? _buildLoadingScreen()
          : product == null
              ? _buildErrorScreen()
              : _buildProductDetail(context),
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

  Widget _buildErrorScreen() {
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
            'Sản phẩm có thể đã bị xóa hoặc không tồn tại',
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

  Widget _buildProductDetail(BuildContext context) {
    final List<String> productImages = [
      product!.anh,
      'https://picsum.photos/400/400?random=1',
      'https://picsum.photos/400/400?random=2',
    ];

    final isOutOfStock = product!.soLuongTon <= 0;
    final isLowStock = product!.soLuongTon < 10 && product!.soLuongTon > 0;

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
                          tag: product!.maSanPham,
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

                    if (isOutOfStock)
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
                                      product!.tenSanPham,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (isOutOfStock)
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
                                    else if (isLowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Text(
                                          'Chỉ còn ${product!.soLuongTon} sản phẩm',
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
                                onTap: _toggleFavorite,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isFavorite 
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isFavorite 
                                          ? Colors.red.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey,
                                      size: 20,
                                      key: ValueKey(isFavorite),
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
                                text: product!.xuatXu,
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.inventory_2_outlined,
                                text: '${product!.soLuongTon} ${product!.donViTinh}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product!.giaBan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey.shade400 : Colors.green.shade600,
                                ),
                              ),
                              _buildRatingWidget(),
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
                        product!.moTa.isNotEmpty
                            ? product!.moTa
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
                          _buildDetailRow("Xuất xứ", product!.xuatXu),
                          _buildDetailRow("Đơn vị tính", product!.donViTinh),
                          _buildDetailRow("Số lượng tồn", "${product!.soLuongTon} ${product!.donViTinh}"),
                          _buildDetailRow("Mã sản phẩm", product!.maSanPham),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PHẦN ĐÁNH GIÁ ĐÃ ĐƯỢC TÍCH HỢP
                    _buildRatingSection(),

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
          child: _buildBottomActionBar(isOutOfStock),
        ),
      ],
    );
  }

  // Các method hỗ trợ khác giữ nguyên
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

  Widget _buildRatingWidget() {
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
            _ratingStats.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${_ratingStats.totalRatings})',
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

  Widget _buildBottomActionBar(bool isOutOfStock) {
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
          if (!isOutOfStock)
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
                      color: quantity > 1 ? Colors.grey.shade700 : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      if (quantity > 1) {
                        setState(() => quantity--);
                      }
                    },
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      "$quantity",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_rounded,
                      color: quantity < product!.soLuongTon ? Colors.green.shade600 : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      if (quantity < product!.soLuongTon) {
                        setState(() => quantity++);
                      } else {
                        _showStockWarningDialog();
                      }
                    },
                  ),
                ],
              ),
            ),
          
          if (!isOutOfStock) const SizedBox(width: 16),
          
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
                onPressed: isOutOfStock ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: isOutOfStock 
                      ? Colors.grey.shade400 
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isOutOfStock ? 0 : 4,
                  shadowColor: isOutOfStock 
                      ? Colors.transparent 
                      : Colors.green.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOutOfStock ? Icons.inventory_2_outlined : Icons.shopping_cart_outlined, 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOutOfStock ? "HẾT HÀNG" : "Thêm vào giỏ hàng",
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

  // Các method thông báo giữ nguyên
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

  void _showStockWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Số lượng không đủ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sản phẩm "${product?.tenSanPham}" chỉ còn ${product?.soLuongTon} sản phẩm. Bạn đã chọn $quantity sản phẩm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        quantity = product!.soLuongTon;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ĐẶT SỐ LƯỢNG TỐI ĐA'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    try {
      if (product == null) {
        _showErrorSnackBar('Sản phẩm không tồn tại');
        return;
      }

      if (product!.soLuongTon <= 0) {
        _showStockErrorDialog();
        return;
      }

      if (quantity > product!.soLuongTon) {
        _showStockWarningDialog();
        return;
      }

      _addToCartController.forward().then((_) {
        _addToCartController.reverse();
      });

      final isLoggedIn = await UserApi().isLoggedIn();
      if (!isLoggedIn) {
        _showLoginRequiredSnackBar();
        return;
      }

      final success = await CartApi().addToCart(product!.maSanPham, quantity);
      if (success) {
        _showSuccessSnackBar('Đã thêm "${product!.tenSanPham}" vào giỏ hàng');
      } else {
        _showErrorSnackBar('Không thể thêm sản phẩm vào giỏ hàng');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    }
  }

  void _showStockErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.red.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hết hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sản phẩm "${product?.tenSanPham}" hiện đã hết hàng. Vui lòng quay lại sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ĐÃ HIỂU'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    _addToCartController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }
}

// Dialog đánh giá
class RatingDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Rating? userRating;
  final VoidCallback onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.userRating,
    required this.onRatingSubmitted,
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
      final user = await UserApi().getCurrentUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đánh giá');
      }

      final rating = Rating(
        maSanPham: widget.productId,
        maTaiKhoan: user.maTaiKhoan,
        soSao: _selectedStars,
        noiDung: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      );

      bool success;
      if (widget.userRating != null && widget.userRating!.soSao > 0) {
        success = await RatingApi().updateRating(rating);
      } else {
        success = await RatingApi().addRating(rating);
      }

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