import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/home/widgets/home_app_bar.dart';
import 'package:fresher_food/roles/user/home/widgets/banner_section.dart';
import 'package:fresher_food/roles/user/home/widgets/categories_section.dart';
import 'package:fresher_food/roles/user/home/widgets/products_section.dart';

/// Màn hình trang chủ - hiển thị banner, danh mục và sản phẩm
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

  /// Khối khởi tạo: Khởi tạo PageController, auto-scroll banner và load dữ liệu
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initializeData();
    });
  }

  /// Khối chức năng: Tự động scroll banner mỗi 3 giây
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

  Future<void> _refreshData() async {
    await context.read<HomeProvider>().initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.green,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            HomeAppBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearch: _handleSearch,
              onResetSearch: _resetSearch,
            ),
            // Banner section
            BannerSection(
              pageController: _pageController,
              banners: banners,
            ),
            // Categories section
            const CategoriesSection(),
            // Products section
            ProductsSection(
              searchController: _searchController,
              onResetSearch: _resetSearch,
            ),
          ],
        ),
      ),
    );
  }

}
