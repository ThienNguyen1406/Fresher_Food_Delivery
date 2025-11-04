import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/page/product_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Product.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late PageController _pageController;
  Timer? _timer;

  List<String> banners = [
    "lib/assets/img/anh1.png",
    "lib/assets/img/anh2.png",
    "lib/assets/img/anh3.png",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();

    // Initialize data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initializeData();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        final provider = context.read<HomeProvider>();
        int nextBanner = provider.currentBanner < banners.length - 1
            ? provider.currentBanner + 1
            : 0;
        _pageController.animateToPage(
          nextBanner,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      FocusScope.of(context).unfocus();
      context.read<HomeProvider>().searchProducts(keyword);
    }
  }

  void _resetSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    context.read<HomeProvider>().resetSearch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          _buildAppBar(),
          // Banner section
          _buildBannerSection(),
          // Categories section
          _buildCategoriesSection(),
          // Products section
          _buildProductsSection(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      collapsedHeight: kToolbarHeight + 20,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Container(
        height: kToolbarHeight,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Xin chào,",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<Map<String, dynamic>>(
                    future: context.read<HomeProvider>().getUserInfo(),
                    builder: (context, snapshot) {
                      final userName =
                          snapshot.data?['tenTaiKhoan'] ?? 'Người dùng';
                      return Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.green,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm sản phẩm...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (value) => _handleSearch(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    onPressed: _resetSearch,
                  ),
                Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: provider.state.isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                        onPressed: _handleSearch,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildBannerSection() {
    return SliverToBoxAdapter(
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: banners.length,
                            onPageChanged: (index) {
                              provider.setCurrentBanner(index);
                            },
                            itemBuilder: (context, index) {
                              return Image.asset(
                                banners[index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      size: 50, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: banners.asMap().entries.map((entry) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: provider.currentBanner == entry.key ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: provider.currentBanner == entry.key
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildCategoriesSection() {
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
          _buildCategoryItem(
            "Tất cả",
            Icons.category,
            provider.state.selectedCategoryId == 'all',
            onTap: () => provider.fetchProductsByCategory('all'),
          ),
          // Các danh mục từ API
          ...provider.state.categories.map((category) => _buildCategoryItem(
                category.tenDanhMuc,
                _getCategoryIcon(category.tenDanhMuc),
                provider.state.selectedCategoryId == category.maDanhMuc,
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

  Widget _buildCategoryItem(String title, IconData icon, bool isActive,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.length > 10 ? '${title.substring(0, 10)}...' : title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.green : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildProductsSection() {
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
            return _buildProductsGrid(provider);
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
                _searchController.text.isEmpty
                    ? 'Không có sản phẩm nào'
                    : 'Không tìm thấy sản phẩm "${_searchController.text}"',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isNotEmpty)
                TextButton(
                  onPressed: _resetSearch,
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

  SliverGrid _buildProductsGrid(HomeProvider provider) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = provider.state.filteredProducts[index];
          return _buildProductCard(product, provider);
        },
        childCount: provider.state.filteredProducts.length,
      ),
    );
  }

  Widget _buildProductCard(Product product, HomeProvider provider) {
    final isFavorite =
        provider.state.favoriteProductIds.contains(product.maSanPham);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                  productId: product.maSanPham,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Image.network(
                            product.anh,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                product.tenSanPham,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Origin
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      product.xuatXu,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // Stock
                              Text(
                                "Còn: ${product.soLuongTon} sp",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: product.soLuongTon > 0
                                      ? Colors.grey.shade600
                                      : Colors.red,
                                  fontWeight: product.soLuongTon > 0
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Price and Add Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${product.giaBan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (product.giaBan !=
                                        product
                                            .giaBan) // This seems incorrect, you might want to check this condition
                                      Text(
                                        "${product.giaBan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add Button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: product.soLuongTon > 0
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  boxShadow: product.soLuongTon > 0
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: product.soLuongTon > 0
                                        ? () => _addToCart(product, provider)
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Icon(
                                      product.soLuongTon > 0
                                          ? Icons.add
                                          : Icons.remove_shopping_cart,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Favorite Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(product, provider),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Out of stock badge
              if (product.soLuongTon <= 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'HẾT HÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Product product, HomeProvider provider) async {
    try {
      await provider.toggleFavorite(product);
      _showSuccessSnackBar(
          provider.state.favoriteProductIds.contains(product.maSanPham)
              ? 'Đã thêm "${product.tenSanPham}" vào yêu thích'
              : 'Đã xóa "${product.tenSanPham}" khỏi yêu thích');
    } catch (e) {
      if (e.toString().contains('đăng nhập')) {
        _showLoginRequiredSnackBar();
      } else {
        _showErrorSnackBar('Lỗi: $e');
      }
    }
  }

  Future<void> _addToCart(Product product, HomeProvider provider) async {
    try {
      await provider.addToCart(product);
      _showSuccessSnackBar('Đã thêm "${product.tenSanPham}" vào giỏ hàng');
    } catch (e) {
      if (e.toString().contains('đăng nhập')) {
        _showLoginRequiredSnackBar();
      } else {
        _showErrorSnackBar('Lỗi: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Vui lòng đăng nhập để sử dụng tính năng này')),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to login screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
