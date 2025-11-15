import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_manager_header.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_search_bar.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_loading_screen.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_empty_screen.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_item_widget.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_delete_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_error_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_add_fab.dart';

class QuanLySanPhamScreen extends StatefulWidget {
  const QuanLySanPhamScreen({super.key});

  @override
  State<QuanLySanPhamScreen> createState() => _QuanLySanPhamScreenState();
}

class _QuanLySanPhamScreenState extends State<QuanLySanPhamScreen> {
  final ProductApi _apiProduct = ProductApi();
  final CategoryApi _apiCategory = CategoryApi();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [products, categories] = await Future.wait([
        _apiProduct.getProducts(),
        _apiCategory.getCategories(),
      ]);
      setState(() {
        _products = List<Product>.from(products);
        _filteredProducts = List<Product>.from(products);
        _categories = List<Category>.from(categories);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi tải dữ liệu', e.toString());
    }
  }

  void _onSearch(String keyword) {
    setState(() => _searchKeyword = keyword);
    if (keyword.isEmpty) {
      setState(() => _filteredProducts = _products);
      return;
    }
    setState(() {
      _filteredProducts = _products.where((product) =>
          product.tenSanPham.toLowerCase().contains(keyword.toLowerCase())).toList();
    });
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        apiService: _apiProduct,
        categories: _categories,
        onSave: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        apiService: _apiProduct,
        categories: _categories,
        product: product,
        onSave: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductDeleteDialog(
        product: product,
        onDelete: (productId) async {
          try {
            final success = await _apiProduct.deleteProduct(productId);
            if (success) {
              _loadData();
              return true;
            } else {
              throw Exception('Xóa thất bại');
            }
          } catch (e) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => ProductErrorDialog(
                  title: 'Lỗi',
                  message: e.toString(),
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => ProductErrorDialog(
        title: title,
        message: message,
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Column(
        children: [
          ProductManagerHeader(
            productCount: _filteredProducts.length,
            onAddProduct: _showAddProductDialog,
          ),
          ProductSearchBar(
            searchController: _searchController,
            searchKeyword: _searchKeyword,
            onSearch: _onSearch,
            onClear: () {
              _searchController.clear();
              _onSearch('');
            },
          ),
          Expanded(
            child: _isLoading
                ? const ProductLoadingScreen()
                : _filteredProducts.isEmpty
                    ? ProductEmptyScreen(
                        searchKeyword: _searchKeyword,
                        onAddProduct: _showAddProductDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF2E7D32),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final category = _categories.firstWhere(
                              (cat) => cat.maDanhMuc == product.maDanhMuc,
                              orElse: () => Category(maDanhMuc: '', tenDanhMuc: 'Chưa phân loại', icon: ''),
                            );
                            return ProductItemWidget(
                              product: product,
                              category: category,
                              onEdit: _showEditProductDialog,
                              onDelete: _showDeleteConfirmation,
                              formatPrice: _formatPrice,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: ProductAddFab(
        onPressed: _showAddProductDialog,
      ),
    );
  }
}
