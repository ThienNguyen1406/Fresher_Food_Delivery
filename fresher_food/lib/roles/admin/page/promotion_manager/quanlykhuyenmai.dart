import 'package:flutter/material.dart';
import 'package:fresher_food/models/Sale.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/sale_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:intl/intl.dart';

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
      
      // Map product names to sales
      final salesWithProductNames = sales.map((sale) {
        // Nếu là khuyến mãi toàn bộ (ALL), hiển thị tên đặc biệt
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận xóa',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
        content: const Text('Bạn có chắc muốn xóa khuyến mãi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                  // Dropdown chọn loại giảm giá
                  DropdownButtonFormField<String>(
                    value: selectedLoaiGiaTri,
                    decoration: InputDecoration(
                      labelText: 'Loại giảm giá',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Amount',
                        child: Row(
                          children: [
                            Icon(Icons.attach_money, size: 20, color: _textSecondary),
                            SizedBox(width: 8),
                            Text('Số tiền cố định (VNĐ)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Percent',
                        child: Row(
                          children: [
                            Icon(Icons.percent, size: 20, color: _textSecondary),
                            SizedBox(width: 8),
                            Text('Phần trăm (%)'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLoaiGiaTri = value ?? 'Amount';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Giá trị khuyến mãi
                  TextFormField(
                    controller: giaTriController,
                    decoration: InputDecoration(
                      labelText: selectedLoaiGiaTri == 'Percent' 
                          ? 'Giá trị khuyến mãi (%)' 
                          : 'Giá trị khuyến mãi (VNĐ)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá trị khuyến mãi';
                      }
                      final giaTri = double.tryParse(value);
                      if (giaTri == null || giaTri <= 0) {
                        return 'Giá trị phải lớn hơn 0';
                      }
                      // Validate phần trăm
                      if (selectedLoaiGiaTri == 'Percent' && (giaTri < 0 || giaTri > 100)) {
                        return 'Phần trăm phải từ 0 đến 100';
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
                  
                  // Validate giá trị khuyến mãi
                  final giaTri = double.tryParse(giaTriController.text);
                  if (giaTri == null || giaTri <= 0) {
                    _showSnackbar('Giá trị khuyến mãi phải lớn hơn 0', false);
                    return;
                  }
                  
                  // Validate phần trăm
                  if (selectedLoaiGiaTri == 'Percent' && (giaTri < 0 || giaTri > 100)) {
                    _showSnackbar('Phần trăm phải từ 0 đến 100', false);
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

                  // Trim mã sản phẩm để đảm bảo không có khoảng trắng
                  final maSanPhamTrimmed = maSanPham.trim();
                  if (maSanPhamTrimmed.isEmpty) {
                    _showSnackbar('Mã sản phẩm không hợp lệ', false);
                    return;
                  }

                  try {
                    print('Creating sale with maSanPham: $maSanPhamTrimmed, loaiGiaTri: $selectedLoaiGiaTri, giaTri: $giaTri');
                    
                    final newSale = Sale(
                      idSale: sale?.idSale ?? '',
                      giaTriKhuyenMai: giaTri,
                      loaiGiaTri: selectedLoaiGiaTri, // Đảm bảo truyền đúng giá trị
                      moTaChuongTrinh: moTaController.text.isEmpty
                          ? null
                          : moTaController.text,
                      ngayBatDau: ngayBatDau!,
                      ngayKetThuc: ngayKetThuc!,
                      trangThai: sale?.trangThai ?? 'Active',
                      maSanPham: maSanPhamTrimmed, // Sử dụng mã đã trim
                    );
                    
                    print('Sale object created: loaiGiaTri=${newSale.loaiGiaTri}, toJson=${newSale.toJson()}');

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
                    // Hiển thị lỗi chi tiết từ backend
                    String errorMessage = 'Lỗi: ';
                    if (e.toString().contains('Exception:')) {
                      errorMessage += e.toString().split('Exception:')[1].trim();
                    } else {
                      errorMessage += e.toString();
                    }
                    _showSnackbar(errorMessage, false);
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

  Color _getStatusColor(Sale sale) {
    if (sale.isExpired) return _textSecondary;
    if (sale.isActive) return _successColor;
    if (sale.isUpcoming) return _warningColor;
    return _textSecondary;
  }

  String _getStatusText(Sale sale) {
    if (sale.isExpired) return 'Đã hết hạn';
    if (sale.isActive) return 'Đang hoạt động';
    if (sale.isUpcoming) return 'Sắp diễn ra';
    return 'Không hoạt động';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Floating action button cho khuyến mãi toàn bộ sản phẩm
          FloatingActionButton(
            heroTag: "global_sale",
            onPressed: () => _showAddEditDialog(isGlobalSale: true),
            backgroundColor: Colors.orange,
            elevation: 4,
            mini: true,
            child: const Icon(Icons.public, color: Colors.white, size: 20),
            tooltip: 'Khuyến mãi toàn bộ sản phẩm',
          ),
          const SizedBox(height: 12),
          // Floating action button cho khuyến mãi sản phẩm cụ thể
          FloatingActionButton(
            heroTag: "product_sale",
            onPressed: () => _showAddEditDialog(isGlobalSale: false),
            backgroundColor: _primaryColor,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
            tooltip: 'Khuyến mãi sản phẩm',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            color: _surfaceColor,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterSales(),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khuyến mãi...',
                  prefixIcon: Icon(Icons.search, color: _textSecondary),
                  filled: true,
                  fillColor: _backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có khuyến mãi nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = _filteredSales[index];
                            return _buildSaleCard(sale);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final statusColor = _getStatusColor(sale);
    final statusText = _getStatusText(sale);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (sale.maSanPham == 'ALL')
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public, size: 14, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'TOÀN BỘ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              sale.tenSanPham ?? sale.maSanPham,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sale.maSanPham != 'ALL') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mã SP: ${sale.maSanPham}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  sale.loaiGiaTri == 'Percent' ? Icons.percent : Icons.attach_money, 
                  size: 20, 
                  color: _primaryColor
                ),
                const SizedBox(width: 8),
                Text(
                  sale.loaiGiaTri == 'Percent'
                      ? '${sale.giaTriKhuyenMai.toStringAsFixed(0)}%'
                      : '${NumberFormat('#,###').format(sale.giaTriKhuyenMai.toInt())} VNĐ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sale.loaiGiaTri == 'Percent' 
                        ? Colors.blue.shade50 
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sale.loaiGiaTri == 'Percent' ? 'THEO %' : 'THEO SỐ TIỀN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: sale.loaiGiaTri == 'Percent' 
                          ? Colors.blue.shade700 
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (sale.moTaChuongTrinh != null &&
                sale.moTaChuongTrinh!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                sale.moTaChuongTrinh!,
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: _textSecondary.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày bắt đầu',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.ngayBatDau),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày kết thúc',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.ngayKetThuc),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEditDialog(sale: sale),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteSale(sale.idSale),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: _errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

