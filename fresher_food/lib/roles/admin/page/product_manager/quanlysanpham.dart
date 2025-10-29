import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Xác nhận xóa',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Bạn có chắc muốn xóa sản phẩm "${product.tenSanPham}"?',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hành động này không thể hoàn tác',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final success = await _apiProduct.deleteProduct(product.maSanPham);
                          if (success) {
                            _loadData();
                            _showSuccessSnackbar('Xóa thành công');
                          } else {
                            throw Exception('Xóa thất bại');
                          }
                        } catch (e) {
                          _showErrorDialog('Lỗi', e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.close_circle, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(message, textAlign: TextAlign.center),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.box, color: Color(0xFF2E7D32), size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quản lý sản phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_filteredProducts.length} sản phẩm',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E7D32)),
                        SizedBox(height: 16),
                        Text('Đang tải sản phẩm...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchKeyword.isEmpty ? Iconsax.box : Iconsax.search_normal,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchKeyword.isEmpty ? 'Chưa có sản phẩm nào' : 'Không tìm thấy sản phẩm',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchKeyword.isEmpty ? 'Hãy thêm sản phẩm đầu tiên của bạn' : 'Thử tìm kiếm với từ khóa khác',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (_searchKeyword.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: ElevatedButton(
                                  onPressed: _showAddProductDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Thêm sản phẩm đầu tiên'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF2E7D32),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            // Tìm tên danh mục từ mã danh mục
                            final category = _categories.firstWhere(
                              (cat) => cat.maDanhMuc == product.maDanhMuc,
                              orElse: () => Category(maDanhMuc: '', tenDanhMuc: 'Chưa phân loại', icon: ''),
                            );
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hình ảnh sản phẩm
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: const Color(0xFFE8F5E8),
                                        image: product.anh.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(product.anh),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: product.anh.isEmpty
                                          ? const Icon(Iconsax.box, color: Color(0xFF2E7D32), size: 24)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Thông tin sản phẩm
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.tenSanPham,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatPrice(product.giaBan),
                                            style: const TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '${product.soLuongTon} ${product.donViTinh}',
                                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: product.soLuongTon > 0 
                                                      ? const Color(0xFFE8F5E8) 
                                                      : const Color(0xFFFFEBEE),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  product.soLuongTon > 0 ? 'Còn hàng' : 'Hết hàng',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: product.soLuongTon > 0 
                                                        ? const Color(0xFF2E7D32)
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Danh mục: ${category.tenDanhMuc}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          if (product.moTa.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              product.moTa,
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Nút hành động
                                    Column(
                                      children: [
                                        _buildActionButton(
                                          onPressed: () => _showEditProductDialog(product),
                                          icon: Iconsax.edit,
                                          color: const Color(0xFF2196F3),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildActionButton(
                                          onPressed: () => _showDeleteConfirmation(product),
                                          icon: Iconsax.trash,
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Iconsax.add, size: 24),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final ProductApi apiService;
  final List<Category> categories;
  final Product? product;
  final VoidCallback onSave;

  const ProductDialog({
    Key? key,
    required this.apiService,
    required this.categories,
    this.product,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _controllers = {};
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _initControllers();
    // Set selected category from product if editing
    if (widget.product != null) {
      _selectedCategoryId = widget.product!.maDanhMuc;
    }
  }

  void _initControllers() {
    _controllers['tenSanPham'] = TextEditingController(text: widget.product?.tenSanPham ?? '');
    _controllers['giaBan'] = TextEditingController(text: widget.product?.giaBan.toString() ?? '');
    _controllers['moTa'] = TextEditingController(text: widget.product?.moTa ?? '');
    _controllers['soLuongTon'] = TextEditingController(text: widget.product?.soLuongTon.toString() ?? '');
    _controllers['donViTinh'] = TextEditingController(text: widget.product?.donViTinh ?? '');
    _controllers['xuatXu'] = TextEditingController(text: widget.product?.xuatXu ?? '');
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Lỗi', 'Không thể chọn ảnh: ${e.toString()}');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.gallery, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Chọn ảnh sản phẩm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildImageSourceButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: Iconsax.camera,
                      text: 'Chụp ảnh mới',
                    ),
                    const SizedBox(height: 12),
                    _buildImageSourceButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      icon: Iconsax.gallery,
                      text: 'Chọn từ thư viện',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2E7D32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E7D32)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _handleSaveProduct() async {
    if (!_validateForm()) return;

    setState(() => _isUploadingImage = true);

    try {
      final newProduct = Product(
        maSanPham: widget.product?.maSanPham ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tenSanPham: _controllers['tenSanPham']!.text,
        giaBan: double.tryParse(_controllers['giaBan']!.text) ?? 0,
        moTa: _controllers['moTa']!.text,
        soLuongTon: int.tryParse(_controllers['soLuongTon']!.text) ?? 0,
        donViTinh: _controllers['donViTinh']!.text,
        xuatXu: _controllers['xuatXu']!.text,
        maDanhMuc: _selectedCategoryId ?? '',
        anh: widget.product?.anh ?? '',
      );

      final success = widget.product != null
          ? await widget.apiService.updateProduct(widget.product!.maSanPham, newProduct, _selectedImage)
          : await widget.apiService.addProduct(newProduct, _selectedImage);

      if (success) {
        widget.onSave();
        _showSuccessSnackbar(widget.product != null ? 'Cập nhật thành công' : 'Thêm thành công');
      } else {
        throw Exception('Thao tác thất bại');
      }
    } catch (e) {
      _showErrorDialog('Lỗi', e.toString());
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  bool _validateForm() {
    if (_controllers['tenSanPham']!.text.isEmpty ||
        _controllers['giaBan']!.text.isEmpty ||
        _controllers['soLuongTon']!.text.isEmpty ||
        _controllers['donViTinh']!.text.isEmpty ||
        _selectedCategoryId == null) {
      _showErrorDialog('Lỗi', 'Vui lòng nhập đầy đủ các trường bắt buộc (*)');
      return false;
    }
    return true;
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final hasExistingImage = widget.product?.anh != null && widget.product!.anh.isNotEmpty;
    final hasNewImage = _selectedImage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Iconsax.gallery, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Hình ảnh sản phẩm',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              image: hasNewImage
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : hasExistingImage
                      ? DecorationImage(
                          image: NetworkImage(widget.product!.anh),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: !hasNewImage && !hasExistingImage
                ? const Icon(Iconsax.gallery, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          _isUploadingImage
              ? const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 8),
                    Text('Đang xử lý...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              : ElevatedButton(
                  onPressed: _showImageSourceDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.gallery_add, size: 16),
                      SizedBox(width: 4),
                      Text('Chọn ảnh'),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? keyboardType,
    int maxLines = 1,
  ]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              icon: const Icon(Iconsax.arrow_down_1, color: Color(0xFF2E7D32)),
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Chọn danh mục'),
              ),
              items: widget.categories.map((Category category) {
                return DropdownMenuItem<String>(
                  value: category.maDanhMuc,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      category.tenDanhMuc,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategoryId = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEdit ? Iconsax.edit_2 : Iconsax.add_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildImageUploadSection(),
                    const SizedBox(height: 16),
                    _buildTextField(_controllers['tenSanPham']!, 'Tên sản phẩm *', Iconsax.box),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_controllers['giaBan']!, 'Giá bán *', Iconsax.dollar_circle, TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_controllers['soLuongTon']!, 'Số lượng tồn *', Iconsax.shop, TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_controllers['donViTinh']!, 'Đơn vị tính *', Iconsax.weight),
                    const SizedBox(height: 16),
                    _buildTextField(_controllers['xuatXu']!, 'Xuất xứ', Iconsax.location),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(_controllers['moTa']!, 'Mô tả', Iconsax.note, null, 3),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isUploadingImage ? null : _handleSaveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEdit ? 'Cập nhật' : 'Thêm'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}