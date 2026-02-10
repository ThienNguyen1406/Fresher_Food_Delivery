import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/page/order_detail_page.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:iconsax/iconsax.dart';
import 'widgets/order_header.dart';
import 'widgets/order_tab_bar.dart';
import 'widgets/order_list.dart';
import 'widgets/order_loading_indicator.dart';
import 'widgets/order_empty_state.dart';

/// Màn hình quản lý đơn hàng - xem, lọc và cập nhật trạng thái đơn hàng
class QuanLyDonHangScreen extends StatefulWidget {
  const QuanLyDonHangScreen({super.key});

  @override
  State<QuanLyDonHangScreen> createState() => _QuanLyDonHangScreenState();
}

class _QuanLyDonHangScreenState extends State<QuanLyDonHangScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang xử lý',
    'Đang giao',
    'Hoàn thành',
    'Đã hủy'
  ];

  // Biến quản lý state
  List<Order> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Màu sắc mới - chủ đạo xanh lá
  final Color _primaryColor = const Color(0xFF10B981); // Xanh lá tươi sáng
  final Color _secondaryColor = const Color(0xFF059669); // Xanh lá đậm
  final Color _accentColor = const Color(0xFF34D399); // Xanh lá nhạt
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _surfaceColor = Colors.white;
  final Color _textColor = const Color(0xFF212529);
  final Color _textLightColor = const Color(0xFF6C757D);

  // Status mapping với màu sắc mới
  final Map<String, String> _statusMap = {
    'pending': 'Chờ xác nhận',
    'processing': 'Đang xử lý',
    'shipping': 'Đang giao',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy',
  };

  final Map<String, Color> _statusColorMap = {
    'pending': Color(0xFFFFB74D), // Cam sáng
    'processing': Color(0xFF42A5F5), // Xanh dương sáng
    'shipping': Color(0xFF7E57C2), // Tím sáng
    'completed': Color(0xFF10B981), // Xanh lá (trùng với primary)
    'cancelled': Color(0xFFEF5350), // Đỏ sáng
  };

  /// Khối khởi tạo: Load danh sách đơn hàng từ server
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Khối chức năng: Load tất cả đơn hàng từ API
  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiService = OrderApi();
      final orders = await apiService.getOrders();

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Lỗi tải danh sách đơn hàng: $e');
    }
  }

  /// Khối chức năng: Cập nhật trạng thái đơn hàng (pending, processing, shipping, completed, cancelled)
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final apiService = OrderApi();
      final success = await apiService.updateOrderStatus(orderId, newStatus);

      if (success) {
        setState(() {
          final index =
              _orders.indexWhere((order) => order.maDonHang == orderId);
          if (index != -1) {
            final oldOrder = _orders[index];
            final updatedOrder = Order(
              maDonHang: oldOrder.maDonHang,
              maTaiKhoan: oldOrder.maTaiKhoan,
              ngayDat: oldOrder.ngayDat,
              trangThai: newStatus,
              diaChiGiaoHang: oldOrder.diaChiGiaoHang,
              soDienThoai: oldOrder.soDienThoai,
              tenNguoiDung: oldOrder.tenNguoiDung,
              ghiChu: oldOrder.ghiChu,
              phuongThucThanhToan: oldOrder.phuongThucThanhToan,
              trangThaiThanhToan: oldOrder.trangThaiThanhToan,
              id_PhieuGiamGia: oldOrder.id_PhieuGiamGia,
              id_Pay: oldOrder.id_Pay,
            );
            _orders[index] = updatedOrder;
          }
        });
        _showSuccessSnackbar('Cập nhật trạng thái thành công');
      }
    } catch (e) {
      _showErrorSnackbar('Lỗi cập nhật trạng thái: $e');
    }
  }

  void _showStatusUpdateDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cập nhật trạng thái',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statusMap.entries.map((entry) {
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColorMap[entry.key],
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                entry.value,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: order.trangThai == entry.key
                  ? Icon(Icons.check, color: _primaryColor, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(order.maDonHang, entry.key);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Order> _getFilteredOrders() {
    var filteredOrders = _orders;

    if (_selectedTab > 0) {
      final statusKeys = _statusMap.keys.toList();
      final status = statusKeys[_selectedTab - 1];
      filteredOrders =
          filteredOrders.where((order) => order.trangThai == status).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders
          .where((order) =>
              order.maDonHang
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (order.soDienThoai ?? '').contains(_searchQuery) ||
              order.maTaiKhoan
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_startDate != null) {
      filteredOrders = filteredOrders.where((order) {
        return order.ngayDat
            .isAfter(_startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (_endDate != null) {
      filteredOrders = filteredOrders.where((order) {
        return order.ngayDat.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return filteredOrders;
  }

  /// Khối chức năng: Xuất danh sách đơn hàng ra Excel
  Future<void> _exportToExcel() async {
    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = OrderApi();
      final result = await apiService.exportToExcel();

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        if (mounted) {
          final filePath = result['filePath'] ?? '';
          final fileName = result['fileName'] ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Đã xuất file Excel thành công!'),
                  const SizedBox(height: 4),
                  Text('File: $fileName', style: const TextStyle(fontSize: 12)),
                  if (filePath.isNotEmpty)
                    Text('Vị trí: $filePath', 
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
              backgroundColor: _primaryColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          final errorMsg = result['error'] ?? 'Không xác định';
          _showErrorSnackbar('Lỗi xuất Excel: $errorMsg');
        }
      }
    } catch (e) {
      // Đóng loading dialog nếu có
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar('Lỗi xuất Excel: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header với search và filter
          OrderHeader(
            searchController: _searchController,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onExportExcel: _exportToExcel,
            onFilter: _showFilterDialog,
            primaryColor: _primaryColor,
            secondaryColor: _secondaryColor,
            accentColor: _accentColor,
            backgroundColor: _backgroundColor,
            surfaceColor: _surfaceColor,
            textLightColor: _textLightColor,
          ),

          // Tab bar
          OrderTabBar(
            tabs: _tabs,
            selectedTab: _selectedTab,
            onTabChanged: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            primaryColor: _primaryColor,
            surfaceColor: _surfaceColor,
            textLightColor: _textLightColor,
          ),

          // Danh sách đơn hàng
          Expanded(
            child: _isLoading
                ? OrderLoadingIndicator(
                    primaryColor: _primaryColor,
                    textLightColor: _textLightColor,
                  )
                : filteredOrders.isEmpty
                    ? OrderEmptyState(
                        backgroundColor: _backgroundColor,
                        textColor: _textColor,
                        textLightColor: _textLightColor,
                      )
                    : OrderList(
                        orders: filteredOrders,
                        statusMap: _statusMap,
                        statusColorMap: _statusColorMap,
                        onViewDetail: _viewOrderDetail,
                        onUpdateStatus: _showStatusUpdateDialog,
                        formatDate: _formatDate,
                        onRefresh: _loadOrders,
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        surfaceColor: _surfaceColor,
                        textColor: _textColor,
                        textLightColor: _textLightColor,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOrders,
        backgroundColor: _primaryColor,
        child: Icon(Iconsax.refresh, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: order.maDonHang),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: _surfaceColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.filter, color: _primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Bộ lọc đơn hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Khoảng thời gian:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(
                                text: _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : '',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Từ ngày',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(
                                text: _endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : '',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Đến ngày',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: _textLightColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Xóa lọc'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        _showSuccessSnackbar('Đã áp dụng bộ lọc');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
