import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_detail_screen.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class QuanLyDonHangScreen extends StatefulWidget {
  const QuanLyDonHangScreen({super.key});

  @override
  State<QuanLyDonHangScreen> createState() => _QuanLyDonHangScreenState();
}

class _QuanLyDonHangScreenState extends State<QuanLyDonHangScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Tất cả', 'Chờ xác nhận', 'Đang xử lý', 'Đang giao', 'Hoàn thành', 'Đã hủy'];
  
  // Biến quản lý state
  List<Order> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
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

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final apiService = Provider.of<OrderApi>(context, listen: false);
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

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final apiService = Provider.of<OrderApi>(context, listen: false);
      final success = await apiService.updateOrderStatus(orderId, newStatus);
      
      if (success) {
        setState(() {
          final index = _orders.indexWhere((order) => order.maDonHang == orderId);
          if (index != -1) {
            final oldOrder = _orders[index];
            final updatedOrder = Order(
              maDonHang: oldOrder.maDonHang,
              maTaiKhoan: oldOrder.maTaiKhoan,
              ngayDat: oldOrder.ngayDat,
              trangThai: newStatus,
              diaChiGiaoHang: oldOrder.diaChiGiaoHang,
              soDienThoai: oldOrder.soDienThoai,
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
      filteredOrders = filteredOrders.where((order) => order.trangThai == status).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) =>
          order.maDonHang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.soDienThoai ?? '').contains(_searchQuery) ||
          order.maTaiKhoan.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_startDate != null) {
      filteredOrders = filteredOrders.where((order) {
        return order.ngayDat.isAfter(_startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (_endDate != null) {
      filteredOrders = filteredOrders.where((order) {
        return order.ngayDat.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return filteredOrders;
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
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Header với search và filter (đã bỏ title)
          _buildHeader(),
          
          // Tab bar
          _buildTabBar(),
          
          // Danh sách đơn hàng
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrderList(filteredOrders),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Đã bỏ hoàn toàn dòng title "Quản lý đơn hàng"
          const SizedBox(height: 8), // Giữ khoảng cách nhẹ
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo mã đơn, số ĐT...',
                      hintStyle: TextStyle(color: _textLightColor),
                      prefixIcon: Icon(Iconsax.search_normal, color: _textLightColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Iconsax.filter, color: Colors.white),
                  onPressed: _showFilterDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTab == index
                    ? _primaryColor
                    : _surfaceColor,
                foregroundColor: _selectedTab == index
                    ? Colors.white
                    : _textLightColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedTab == index
                        ? _primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: _loadOrders,
        backgroundColor: _surfaceColor,
        color: _primaryColor,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusText = _statusMap[order.trangThai] ?? 'Không xác định';
    final statusColor = _statusColorMap[order.trangThai] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với mã đơn hàng và trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đơn hàng',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.maDonHang,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Thông tin khách hàng
            Row(
              children: [
                Icon(Iconsax.profile_circle, size: 16, color: _textLightColor),
                const SizedBox(width: 8),
                Text(
                  'Mã TK: ${order.maTaiKhoan}',
                  style: TextStyle(color: _textColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.call, size: 16, color: _textLightColor),
                const SizedBox(width: 8),
                Text(
                  order.soDienThoai ?? 'Chưa có SĐT',
                  style: TextStyle(color: _textColor),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Thông tin đơn hàng
            Row(
              children: [
                Icon(Iconsax.calendar, size: 16, color: _textLightColor),
                const SizedBox(width: 8),
                Text(
                  'Ngày: ${_formatDate(order.ngayDat)}',
                  style: TextStyle(color: _textColor),
                ),
              ],
            ),

            // Địa chỉ giao hàng
            if (order.diaChiGiaoHang != null && order.diaChiGiaoHang!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.location, size: 16, color: _textLightColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.diaChiGiaoHang!,
                      style: TextStyle(
                        color: _textLightColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Tổng tiền và actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.trangThaiThanhToan,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    if (order.phuongThucThanhToan != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'PTTT: ${order.phuongThucThanhToan}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textLightColor,
                        ),
                      ),
                    ]
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Iconsax.eye, size: 20, color: _accentColor),
                        onPressed: () => _viewOrderDetail(order),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Iconsax.edit, size: 20, color: _primaryColor),
                        onPressed: () => _showStatusUpdateDialog(order),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              backgroundColor: _primaryColor.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải đơn hàng...',
            style: TextStyle(
              color: _textLightColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shopping_bag,
                size: 50,
                color: _textLightColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thử thay đổi bộ lọc hoặc tìm kiếm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textLightColor,
              ),
            ),
          ],
        ),
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
        builder: (context) => OrderDetailScreen(orderId: order.maDonHang),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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