import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_image_upload_section.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_form_field.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_category_dropdown.dart';
import 'package:fresher_food/roles/admin/page/product_manager/widgets/product_image_source_dialog.dart';

class ProductDialog extends StatefulWidget {
  final ProductApi apiService;
  final List<Category> categories;
  final Product? product;
  final VoidCallback onSave;

  const ProductDialog({
    super.key,
    required this.apiService,
    required this.categories,
    this.product,
    required this.onSave,
  });

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
      builder: (context) => ProductImageSourceDialog(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
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
                    ProductImageUploadSection(
                      product: widget.product,
                      selectedImage: _selectedImage,
                      isUploading: _isUploadingImage,
                      onPickImage: _showImageSourceDialog,
                    ),
                    const SizedBox(height: 16),
                    ProductFormField(
                      controller: _controllers['tenSanPham']!,
                      label: 'Tên sản phẩm *',
                      icon: Iconsax.box,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ProductFormField(
                            controller: _controllers['giaBan']!,
                            label: 'Giá bán *',
                            icon: Iconsax.dollar_circle,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ProductFormField(
                            controller: _controllers['soLuongTon']!,
                            label: 'Số lượng tồn *',
                            icon: Iconsax.shop,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProductFormField(
                      controller: _controllers['donViTinh']!,
                      label: 'Đơn vị tính *',
                      icon: Iconsax.weight,
                    ),
                    const SizedBox(height: 16),
                    ProductFormField(
                      controller: _controllers['xuatXu']!,
                      label: 'Xuất xứ',
                      icon: Iconsax.location,
                    ),
                    const SizedBox(height: 16),
                    ProductCategoryDropdown(
                      categories: widget.categories,
                      selectedCategoryId: _selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ProductFormField(
                      controller: _controllers['moTa']!,
                      label: 'Mô tả',
                      icon: Iconsax.note,
                      maxLines: 3,
                    ),
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

