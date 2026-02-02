import 'package:flutter/material.dart';
import 'package:fresher_food/models/Sale.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/sale_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:intl/intl.dart';
import 'widgets/promotion_search_bar.dart';
import 'widgets/promotion_loading_indicator.dart';
import 'widgets/promotion_empty_state.dart';
import 'widgets/promotion_list.dart';
import 'widgets/promotion_delete_dialog.dart';
import 'widgets/promotion_floating_buttons.dart';

class QuanLyKhuyenMaiScreen extends StatefulWidget {
  const QuanLyKhuyenMaiScreen({super.key});

  @override
  State<QuanLyKhuyenMaiScreen> createState() => _QuanLyKhuyenMaiScreenState();
}

class _QuanLyKhuyenMaiScreenState extends State<QuanLyKhuyenMaiScreen> {
  final SaleApi _saleApi = SaleApi();
  final ProductApi _productApi = ProductApi();
  final TextEditingController _searchController = TextEditingController();
  List<Sale> _sales = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Color palette
  final Color _primaryColor = const Color(0xFF4CAF50);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF0F172A);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final sales = await _saleApi.getAllSales();
      final products = await _productApi.getProducts();
      
      final salesWithProductNames = sales.map((sale) {
        if (sale.maSanPham == 'ALL') {
          return Sale(
            idSale: sale.idSale,
            giaTriKhuyenMai: sale.giaTriKhuyenMai,
            loaiGiaTri: sale.loaiGiaTri,
            moTaChuongTrinh: sale.moTaChuongTrinh,
            ngayBatDau: sale.ngayBatDau,
            ngayKetThuc: sale.ngayKetThuc,
            trangThai: sale.trangThai,
            maSanPham: sale.maSanPham,
            tenSanPham: 'TẤT CẢ SẢN PHẨM',
          );
        }
        
        final product = products.firstWhere(
          (p) => p.maSanPham == sale.maSanPham,
          orElse: () => Product(
            maSanPham: sale.maSanPham,
            tenSanPham: sale.maSanPham,
            moTa: '',
            giaBan: 0,
            anh: '',
            soLuongTon: 0,
            donViTinh: '',
            xuatXu: '',
            maDanhMuc: '',
          ),
        );
        return Sale(
          idSale: sale.idSale,
          giaTriKhuyenMai: sale.giaTriKhuyenMai,
          loaiGiaTri: sale.loaiGiaTri,
          moTaChuongTrinh: sale.moTaChuongTrinh,
          ngayBatDau: sale.ngayBatDau,
          ngayKetThuc: sale.ngayKetThuc,
          trangThai: sale.trangThai,
          maSanPham: sale.maSanPham,
          tenSanPham: product.tenSanPham,
        );
      }).toList();

      setState(() {
        _sales = salesWithProductNames;
        _products = products;
      });
    } catch (e) {
      _showSnackbar('Lỗi tải dữ liệu: $e', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSales() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<Sale> get _filteredSales {
    if (_searchQuery.isEmpty) return _sales;
    return _sales.where((sale) {
      final query = _searchQuery.toLowerCase();
      return (sale.tenSanPham ?? sale.maSanPham).toLowerCase().contains(query) ||
          (sale.moTaChuongTrinh ?? '').toLowerCase().contains(query) ||
          sale.maSanPham.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteSale(String id) async {
    final confirm = await PromotionDeleteDialog.show(
      context,
      textPrimary: _textPrimary,
      textSecondary: _textSecondary,
      errorColor: _errorColor,
    );

    if (confirm == true) {
      try {
        final success = await _saleApi.deleteSale(id);
        if (success) {
          _showSnackbar('Xóa khuyến mãi thành công', true);
          _loadData();
        } else {
          _showSnackbar('Xóa khuyến mãi thất bại', false);
        }
      } catch (e) {
        _showSnackbar('Lỗi: $e', false);
      }
    }
  }

  Future<void> _showAddEditDialog({Sale? sale, bool isGlobalSale = false}) async {
    final formKey = GlobalKey<FormState>();
    final giaTriController = TextEditingController(
        text: sale?.giaTriKhuyenMai.toString() ?? '');
    final moTaController =
        TextEditingController(text: sale?.moTaChuongTrinh ?? '');
    DateTime? ngayBatDau = sale?.ngayBatDau;
    DateTime? ngayKetThuc = sale?.ngayKetThuc;
    String? selectedProductId = sale?.maSanPham;
    String selectedLoaiGiaTri = sale?.loaiGiaTri ?? 'Amount';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            sale == null 
                ? (isGlobalSale ? 'Thêm khuyến mãi toàn bộ sản phẩm' : 'Thêm khuyến mãi sản phẩm')
                : 'Sửa khuyến mãi',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chọn sản phẩm (chỉ hiển thị khi không phải khuyến mãi toàn bộ)
                  if (!isGlobalSale && sale?.maSanPham != 'ALL')
                    DropdownButtonFormField<String>(
                      value: selectedProductId,
                      decoration: InputDecoration(
                        labelText: 'Sản phẩm',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product.maSanPham,
                          child: Text(product.tenSanPham),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedProductId = value;
                        });
                      },
                      validator: (value) {
                        if (!isGlobalSale && (value == null || value.isEmpty)) {
                          return 'Vui lòng chọn sản phẩm';
                        }
                        return null;
                      },
                    ),
                  if (!isGlobalSale && sale?.maSanPham != 'ALL')
                    const SizedBox(height: 16),
                  // Thông báo cho khuyến mãi toàn bộ
                  if (isGlobalSale || sale?.maSanPham == 'ALL')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Khuyến mãi này sẽ áp dụng cho TẤT CẢ sản phẩm',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isGlobalSale || sale?.maSanPham == 'ALL')
                    const SizedBox(height: 16),
                  // Giá trị khuyến mãi
                  TextFormField(
                    controller: giaTriController,
                    decoration: InputDecoration(
                      labelText: 'Giá trị khuyến mãi (VNĐ)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá trị khuyến mãi';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Giá trị phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Mô tả
                  TextFormField(
                    controller: moTaController,
                    keyboardType: TextInputType.multiline,
                    enableInteractiveSelection: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Mô tả chương trình',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Ngày bắt đầu
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: ngayBatDau ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(ngayBatDau ?? DateTime.now()),
                        );
                        if (time != null) {
                          setDialogState(() {
                            ngayBatDau = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ngày bắt đầu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        ngayBatDau != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(ngayBatDau!)
                            : 'Chọn ngày bắt đầu',
                        style: TextStyle(
                          color: ngayBatDau != null ? _textPrimary : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ngày kết thúc
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: ngayKetThuc ??
                            (ngayBatDau ?? DateTime.now())
                                .add(const Duration(days: 7)),
                        firstDate: ngayBatDau ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              ngayKetThuc ?? DateTime.now()),
                        );
                        if (time != null) {
                          setDialogState(() {
                            ngayKetThuc = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ngày kết thúc',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        ngayKetThuc != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(ngayKetThuc!)
                            : 'Chọn ngày kết thúc',
                        style: TextStyle(
                          color: ngayKetThuc != null ? _textPrimary : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (ngayBatDau == null || ngayKetThuc == null) {
                    _showSnackbar('Vui lòng chọn đầy đủ ngày bắt đầu và kết thúc', false);
                    return;
                  }
                  if (ngayKetThuc!.isBefore(ngayBatDau!) ||
                      ngayKetThuc!.isAtSameMomentAs(ngayBatDau!)) {
                    _showSnackbar('Ngày kết thúc phải sau ngày bắt đầu', false);
                    return;
                  }
                  
                  // Nếu là khuyến mãi toàn bộ, không cần chọn sản phẩm
                  final maSanPham = isGlobalSale || sale?.maSanPham == 'ALL' 
                      ? 'ALL' 
                      : (selectedProductId ?? sale?.maSanPham);
                  
                  if (maSanPham == null || maSanPham.isEmpty) {
                    _showSnackbar('Vui lòng chọn sản phẩm', false);
                    return;
                  }

                  try {
                    final newSale = Sale(
                      idSale: sale?.idSale ?? '',
                      giaTriKhuyenMai: double.parse(giaTriController.text),
                      loaiGiaTri: selectedLoaiGiaTri,
                      moTaChuongTrinh: moTaController.text.isEmpty
                          ? null
                          : moTaController.text,
                      ngayBatDau: ngayBatDau!,
                      ngayKetThuc: ngayKetThuc!,
                      trangThai: sale?.trangThai ?? 'Active',
                      maSanPham: maSanPham,
                    );

                    if (sale == null) {
                      await _saleApi.createSale(newSale);
                      _showSnackbar('Thêm khuyến mãi thành công', true);
                    } else {
                      await _saleApi.updateSale(sale.idSale, newSale);
                      _showSnackbar('Cập nhật khuyến mãi thành công', true);
                    }
                    Navigator.pop(context);
                    _loadData();
                  } catch (e) {
                    _showSnackbar('Lỗi: $e', false);
                  }
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _successColor : _errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: PromotionFloatingButtons(
        onGlobalSalePressed: () => _showAddEditDialog(isGlobalSale: true),
        onProductSalePressed: () => _showAddEditDialog(isGlobalSale: false),
        primaryColor: _primaryColor,
      ),
      body: Column(
        children: [
          // Search bar
          PromotionSearchBar(
            controller: _searchController,
            onChanged: _filterSales,
            backgroundColor: _backgroundColor,
            surfaceColor: _surfaceColor,
            textSecondary: _textSecondary,
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const PromotionLoadingIndicator()
                : _filteredSales.isEmpty
                    ? PromotionEmptyState(textSecondary: _textSecondary)
                    : PromotionList(
                        sales: _filteredSales,
                        onRefresh: _loadData,
                        onEdit: (sale) => _showAddEditDialog(sale: sale),
                        onDelete: _deleteSale,
                        textPrimary: _textPrimary,
                        textSecondary: _textSecondary,
                        primaryColor: _primaryColor,
                        errorColor: _errorColor,
                      ),
          ),
        ],
      ),
    );
  }
}

