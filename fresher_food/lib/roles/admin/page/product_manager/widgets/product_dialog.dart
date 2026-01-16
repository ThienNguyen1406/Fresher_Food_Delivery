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
  DateTime? _ngaySanXuat;
  DateTime? _ngayHetHan;

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
    
    // Khởi tạo ngày sản xuất và hạn sử dụng
    _ngaySanXuat = widget.product?.ngaySanXuat;
    _ngayHetHan = widget.product?.ngayHetHan;
    
    // Tạo controller cho hiển thị ngày (chỉ để hiển thị, không dùng để edit)
    _controllers['ngaySanXuat'] = TextEditingController(
      text: _ngaySanXuat != null 
        ? '${_ngaySanXuat!.day}/${_ngaySanXuat!.month}/${_ngaySanXuat!.year}'
        : ''
    );
    _controllers['ngayHetHan'] = TextEditingController(
      text: _ngayHetHan != null 
        ? '${_ngayHetHan!.day}/${_ngayHetHan!.month}/${_ngayHetHan!.year}'
        : ''
    );
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
      // Parse giá và số lượng với validation đã kiểm tra ở _validateForm
      final giaBan = double.parse(_controllers['giaBan']!.text);
      final soLuongTon = int.parse(_controllers['soLuongTon']!.text);

      final newProduct = Product(
        maSanPham: widget.product?.maSanPham ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tenSanPham: _controllers['tenSanPham']!.text,
        giaBan: giaBan,
        moTa: _controllers['moTa']!.text,
        soLuongTon: soLuongTon,
        donViTinh: _controllers['donViTinh']!.text,
        xuatXu: _controllers['xuatXu']!.text,
        maDanhMuc: _selectedCategoryId ?? '',
        anh: widget.product?.anh ?? '',
        ngaySanXuat: _ngaySanXuat,
        ngayHetHan: _ngayHetHan,
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
      // Xử lý lỗi từ backend hoặc lỗi parse
      String errorMessage = 'Đã xảy ra lỗi';
      if (e.toString().contains('Giá sản phẩm')) {
        errorMessage = 'Giá sản phẩm không hợp lệ';
      } else if (e.toString().contains('Số lượng')) {
        errorMessage = 'Số lượng tồn không hợp lệ';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      _showErrorDialog('Lỗi', errorMessage);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  bool _validateForm() {
    // Kiểm tra các trường bắt buộc
    if (_controllers['tenSanPham']!.text.isEmpty ||
        _controllers['giaBan']!.text.isEmpty ||
        _controllers['soLuongTon']!.text.isEmpty ||
        _controllers['donViTinh']!.text.isEmpty ||
        _selectedCategoryId == null) {
      _showErrorDialog('Lỗi', 'Vui lòng nhập đầy đủ các trường bắt buộc (*)');
      return false;
    }

    // Validation: Giá sản phẩm phải là số và không thể nhỏ hơn 0
    final giaBanValue = double.tryParse(_controllers['giaBan']!.text);
    if (giaBanValue == null) {
      _showErrorDialog('Lỗi', 'Giá sản phẩm phải là số');
      return false;
    }
    if (giaBanValue < 0) {
      _showErrorDialog('Lỗi', 'Giá sản phẩm không thể nhỏ hơn 0');
      return false;
    }

    // Validation: Số lượng tồn phải là số và >= 0
    final soLuongTonValue = int.tryParse(_controllers['soLuongTon']!.text);
    if (soLuongTonValue == null) {
      _showErrorDialog('Lỗi', 'Số lượng tồn phải là số');
      return false;
    }
    if (soLuongTonValue < 0) {
      _showErrorDialog('Lỗi', 'Số lượng tồn phải lớn hơn hoặc bằng 0');
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

  Future<void> _selectDate(BuildContext context, {required bool isProductionDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isProductionDate 
        ? (_ngaySanXuat ?? DateTime.now())
        : (_ngayHetHan ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
      helpText: isProductionDate ? 'Chọn ngày sản xuất' : 'Chọn hạn sử dụng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    
    if (picked != null) {
      setState(() {
        if (isProductionDate) {
          _ngaySanXuat = picked;
          _controllers['ngaySanXuat']!.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _ngayHetHan = picked;
          _controllers['ngayHetHan']!.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
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
                    // Ngày sản xuất và Hạn sử dụng
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, isProductionDate: true),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _controllers['ngaySanXuat']!,
                                decoration: InputDecoration(
                                  labelText: 'Ngày sản xuất',
                                  prefixIcon: const Icon(Iconsax.calendar, color: Color(0xFF2E7D32)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, isProductionDate: false),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _controllers['ngayHetHan']!,
                                decoration: InputDecoration(
                                  labelText: 'Hạn sử dụng',
                                  prefixIcon: const Icon(Iconsax.calendar_1, color: Color(0xFF2E7D32)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

