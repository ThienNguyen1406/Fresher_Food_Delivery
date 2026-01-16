import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_manager_header.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_search_bar.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_loading_screen.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_empty_screen.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_item_widget.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_delete_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_error_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_dialog.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_add_fab.dart';

/// Màn hình quản lý sản phẩm - CRUD sản phẩm và quản lý thùng rác
class QuanLySanPhamScreen extends StatefulWidget {
  const QuanLySanPhamScreen({super.key});

  @override
  State<QuanLySanPhamScreen> createState() => _QuanLySanPhamScreenState();
}

class _QuanLySanPhamScreenState extends State<QuanLySanPhamScreen> with SingleTickerProviderStateMixin {
  final ProductApi _apiProduct = ProductApi();
  final CategoryApi _apiCategory = CategoryApi();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _trashProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingTrash = false;
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  /// Khối khởi tạo: Khởi tạo TabController (Sản phẩm/Thùng rác) và load dữ liệu
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _trashProducts.isEmpty) {
        _loadTrashData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Khối chức năng: Load danh sách sản phẩm và danh mục từ server
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [products, categories] = await Future.wait([
        _apiProduct.getProducts(originalPrice: true), // Admin: lấy giá gốc, không tính giảm giá
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

  /// Khối chức năng: Load danh sách sản phẩm đã xóa (thùng rác)
  Future<void> _loadTrashData() async {
    setState(() => _isLoadingTrash = true);
    try {
      final trashProducts = await _apiProduct.getTrashProducts();
      setState(() {
        _trashProducts = trashProducts;
        _isLoadingTrash = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrash = false);
      if (mounted) {
        _showErrorDialog('Lỗi tải thùng rác', e.toString());
      }
    }
  }

  /// Khối chức năng: Tìm kiếm sản phẩm theo tên
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
              if (context.mounted) {
                _loadData();
              }
              return true;
            } else {
              throw Exception('Xóa thất bại');
            }
          } catch (e) {
            if (context.mounted) {
              // Lấy message lỗi từ exception
              String errorMessage = e.toString();
              if (errorMessage.contains('Exception: ')) {
                errorMessage = errorMessage.replaceFirst('Exception: ', '');
              }
              
              showDialog(
                context: context,
                builder: (context) => ProductErrorDialog(
                  title: 'Không thể xóa sản phẩm',
                  message: errorMessage,
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

  void _showRestoreConfirmation(Map<String, dynamic> trashProduct) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục sản phẩm'),
        content: Text('Bạn có chắc muốn khôi phục sản phẩm "${trashProduct['tenSanPham']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _apiProduct.restoreProduct(trashProduct['maSanPham']);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Khôi phục sản phẩm thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                  _loadTrashData();
                }
              } catch (e) {
                if (mounted) {
                  _showErrorDialog('Lỗi', e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteConfirmation(Map<String, dynamic> trashProduct) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.red[700], size: 24),
            const SizedBox(width: 12),
            const Text(
              'Xóa vĩnh viễn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa vĩnh viễn sản phẩm "${trashProduct['tenSanPham']}"?\n\nHành động này không thể hoàn tác!',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _apiProduct.permanentDeleteProduct(trashProduct['maSanPham']);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa vĩnh viễn sản phẩm'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTrashData();
                }
              } catch (e) {
                if (mounted) {
                  // Lấy message lỗi từ exception và loại bỏ prefix "Exception: "
                  String errorMessage = e.toString();
                  if (errorMessage.contains('Exception: ')) {
                    errorMessage = errorMessage.replaceFirst('Exception: ', '');
                  }
                  _showErrorDialog('Lỗi', errorMessage);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Column(
        children: [
          ProductManagerHeader(
            productCount: _tabController.index == 0 ? _filteredProducts.length : _trashProducts.length,
            onAddProduct: _showAddProductDialog,
          ),
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              tabs: const [
                Tab(text: 'Sản phẩm', icon: Icon(Icons.inventory_2)),
                Tab(text: 'Thùng rác', icon: Icon(Icons.delete_outline)),
              ],
            ),
          ),
          // Search Bar (chỉ hiển thị ở tab Sản phẩm)
          if (_tabController.index == 0)
            ProductSearchBar(
              searchController: _searchController,
              searchKeyword: _searchKeyword,
              onSearch: _onSearch,
              onClear: () {
                _searchController.clear();
                _onSearch('');
              },
            ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Sản phẩm
                _isLoading
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
                // Tab 2: Thùng rác
                _isLoadingTrash
                    ? const Center(child: CircularProgressIndicator())
                    : _trashProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Thùng rác trống',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Các sản phẩm đã xóa sẽ được hiển thị ở đây',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTrashData,
                            color: const Color(0xFF2E7D32),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _trashProducts.length,
                              itemBuilder: (context, index) {
                                final trashProduct = _trashProducts[index];
                                final product = Product.fromJson(trashProduct);
                                final category = _categories.firstWhere(
                                  (cat) => cat.maDanhMuc == product.maDanhMuc,
                                  orElse: () => Category(maDanhMuc: '', tenDanhMuc: 'Chưa phân loại', icon: ''),
                                );
                                final daysUntilDelete = trashProduct['daysUntilPermanentDelete'] as int? ?? 0;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey[300]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ProductItemWidget(
                                        product: product,
                                        category: category,
                                        onEdit: null, // Không cho sửa trong thùng rác
                                        onDelete: null, // Không cho xóa trong thùng rác
                                        formatPrice: _formatPrice,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: daysUntilDelete <= 7 
                                              ? Colors.orange[50] 
                                              : Colors.grey[50],
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: daysUntilDelete <= 7 
                                                  ? Colors.orange[700] 
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                daysUntilDelete > 0
                                                    ? 'Còn $daysUntilDelete ngày trước khi tự động xóa vĩnh viễn'
                                                    : 'Sẽ tự động xóa vĩnh viễn hôm nay',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: daysUntilDelete <= 7 
                                                      ? Colors.orange[700] 
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () => _showRestoreConfirmation(trashProduct),
                                              icon: const Icon(Icons.restore, size: 18),
                                              label: const Text('Khôi phục'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFF2E7D32),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            TextButton.icon(
                                              onPressed: () => _showPermanentDeleteConfirmation(trashProduct),
                                              icon: const Icon(Icons.delete_forever, size: 18),
                                              label: const Text('Xóa vĩnh viễn'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? ProductAddFab(
              onPressed: _showAddProductDialog,
            )
          : null,
    );
  }
}
