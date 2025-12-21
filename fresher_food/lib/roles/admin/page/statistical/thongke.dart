import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/admin/page/order_manager/quanlydonhang.dart';
import 'package:fresher_food/roles/admin/page/user_manager/quanlynguoidung.dart';
import 'package:fresher_food/roles/admin/page/product_manager/quanlysanpham.dart';

/// Màn hình thống kê - hiển thị các số liệu và biểu đồ thống kê doanh thu, đơn hàng
class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  bool _loading = true;
  int tongDonHang = 0;
  double doanhThu = 0.0;
  int tongNguoiDung = 0;
  int tongSanPham = 0;
  List<OrderDetail> allOrderDetails = [];

  // Thống kê doanh thu theo khoảng thời gian
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loadingRevenue = false;
  double _revenueByDateRange = 0.0;
  int _ordersByDateRange = 0;
  int _customersByDateRange = 0;
  int _donThanhCong = 0;
  int _donBiHuy = 0;

  // Thống kê doanh thu theo tháng
  List<Map<String, dynamic>> _monthlyRevenue = [];
  bool _loadingMonthlyRevenue = false;
  int _selectedYear = DateTime.now().year;

  // Dữ liệu cho biểu đồ
  List<Map<String, dynamic>> _statusDistribution = [];
  bool _loadingStatusDistribution = false;
  List<Map<String, dynamic>> _monthlyOrderGrowth = [];
  bool _loadingMonthlyOrderGrowth = false;

  /// Khối khởi tạo: Load tất cả dữ liệu thống kê
  @override
  void initState() {
    super.initState();
    loadStats();
    loadMonthlyRevenue();
    loadMonthlyOrderGrowth();
  }

  /// Khối chức năng: Load thống kê tổng quan (tổng đơn hàng, doanh thu, người dùng, sản phẩm)
  Future<void> loadStats() async {
    setState(() => _loading = true);
    try {
      // 1. Tổng đơn hàng và doanh thu
      final donHangs = await OrderApi().getOrders();
      tongDonHang = donHangs.length;

      // Lọc chỉ lấy đơn hàng đã hoàn thành (complete)
      final completedOrders = donHangs.where((order) {
        final status = order.trangThai.toLowerCase();
        return status.contains('hoàn thành') || 
               status.contains('đã giao hàng') ||
               status.contains('complete');
      }).toList();

      // Lấy tất cả order details và tính doanh thu CHỈ từ đơn hàng đã hoàn thành
      allOrderDetails = [];
      for (var donHang in completedOrders) {
        try {
          final orderDetail =
              await OrderApi().getOrderDetail(donHang.maDonHang);
          if (orderDetail.containsKey('orderDetails')) {
            final details = orderDetail['orderDetails'] as List<dynamic>;
            allOrderDetails
                .addAll(details.map((e) => OrderDetail.fromJson(e)).toList());
          } else {
            debugPrint(
                "⚠️ orderDetail không có key 'orderDetails' cho ${donHang.maDonHang}");
          }
        } catch (e) {
          debugPrint("Lỗi fetch order details cho ${donHang.maDonHang}: $e");
        }
      }

      // Tính tổng doanh thu từ order details (chỉ đơn hàng đã hoàn thành)
      doanhThu = allOrderDetails.fold(
          0.0, (sum, detail) => sum + (detail.giaBan * detail.soLuong));

      // 2. Tổng người dùng
      final nguoiDungs = await UserApi().getUsers();
      tongNguoiDung = nguoiDungs.length;

      // 3. Tổng sản phẩm
      final sanPhams = await ProductApi().getProducts();
      tongSanPham = sanPhams.length;
    } catch (e) {
      debugPrint("Lỗi fetch dashboard: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Hàm format tiền
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Khối chức năng: Load thống kê doanh thu theo khoảng thời gian được chọn
  Future<void> loadRevenueStatistics() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ từ ngày và đến ngày'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra ngày hợp lệ
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc phải sau ngày bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _loadingRevenue = true;
      // Reset giá trị trước khi load
      _revenueByDateRange = 0.0;
      _ordersByDateRange = 0;
      _customersByDateRange = 0;
    });

    try {
      print(
          '📊 Loading revenue statistics from ${_startDate!.toIso8601String().split('T')[0]} to ${_endDate!.toIso8601String().split('T')[0]}');

      final statistics = await OrderApi().getRevenueStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );

      print('📊 Statistics received: $statistics');

      setState(() {
        _revenueByDateRange =
            (statistics['tongDoanhThu'] as num?)?.toDouble() ?? 0.0;
        _ordersByDateRange = statistics['tongDonHang'] as int? ?? 0;
        _customersByDateRange = statistics['tongKhachHang'] as int? ?? 0;
        _donThanhCong = statistics['donThanhCong'] as int? ?? 0;
        _donBiHuy = statistics['donBiHuy'] as int? ?? 0;
        _loadingRevenue = false;
      });

      // Load dữ liệu cho pie chart
      await loadStatusDistribution();

      print(
          '📊 Final values: Revenue=${_revenueByDateRange}, Orders=${_ordersByDateRange}, Customers=${_customersByDateRange}');
    } catch (e) {
      debugPrint("❌ Lỗi fetch thống kê doanh thu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải thống kê: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loadingRevenue = false);
    }
  }

  // Load thống kê doanh thu theo tháng
  /// Khối chức năng: Load thống kê doanh thu theo tháng trong năm được chọn
  Future<void> loadMonthlyRevenue() async {
    setState(() {
      _loadingMonthlyRevenue = true;
    });

    try {
      print('📊 Loading monthly revenue for year: $_selectedYear');
      final monthlyData = await OrderApi().getMonthlyRevenue(year: _selectedYear);
      
      setState(() {
        _monthlyRevenue = monthlyData;
        _loadingMonthlyRevenue = false;
      });

      print('📊 Monthly revenue loaded: ${_monthlyRevenue.length} months');
    } catch (e) {
      debugPrint("❌ Lỗi fetch thống kê doanh thu theo tháng: $e");
      setState(() {
        _loadingMonthlyRevenue = false;
      });
    }
  }

  // Load phân bố trạng thái đơn hàng (cho pie chart)
  Future<void> loadStatusDistribution() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _loadingStatusDistribution = true;
    });

    try {
      final distribution = await OrderApi().getOrderStatusDistribution(
        startDate: _startDate,
        endDate: _endDate,
      );
      
      setState(() {
        _statusDistribution = distribution;
        _loadingStatusDistribution = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi fetch phân bố trạng thái: $e");
      setState(() {
        _loadingStatusDistribution = false;
      });
    }
  }

  // Load tăng trưởng đơn hàng theo tháng (cho line chart)
  /// Khối chức năng: Load thống kê tăng trưởng đơn hàng theo tháng
  Future<void> loadMonthlyOrderGrowth() async {
    setState(() {
      _loadingMonthlyOrderGrowth = true;
    });

    try {
      final growth = await OrderApi().getMonthlyOrderGrowth(year: _selectedYear);
      
      setState(() {
        _monthlyOrderGrowth = growth;
        _loadingMonthlyOrderGrowth = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi fetch tăng trưởng đơn hàng: $e");
      setState(() {
        _loadingMonthlyOrderGrowth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Tổng đơn hàng',
        'value': _loading ? '...' : '$tongDonHang',
        'icon': Icons.shopping_cart,
        'color': Colors.blue,
        'gradient': [Colors.blue, Colors.lightBlue],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuanLyDonHangScreen(),
              ),
            ),
      },
      {
        'title': 'Doanh thu',
        'value': _loading ? '...' : '${formatCurrency(doanhThu)}₫',
        'icon': Icons.monetization_on,
        'color': Colors.green,
        'gradient': [Colors.green, Colors.lightGreen],
        'route': null, // Doanh thu không điều hướng, chỉ hiển thị thống kê
      },
      {
        'title': 'Người dùng',
        'value': _loading ? '...' : '$tongNguoiDung',
        'icon': Icons.people,
        'color': Colors.orange,
        'gradient': [Colors.orange, Colors.amber],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuanLyNguoiDungScreen(),
              ),
            ),
      },
      {
        'title': 'Sản phẩm',
        'value': _loading ? '...' : '$tongSanPham',
        'icon': Icons.fastfood,
        'color': Colors.purple,
        'gradient': [Colors.purple, Colors.deepPurple],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuanLySanPhamScreen(),
              ),
            ),
      },
    ];

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Statistics Cards
            _buildStatsGrid(stats),
            const SizedBox(height: 30),

            // Thống kê doanh thu theo khoảng thời gian
            _buildRevenueByDateRangeSection(),
            const SizedBox(height: 30),

            // Line Chart - Tăng trưởng đơn hàng theo tháng
            _buildOrderGrowthLineChart(),
            const SizedBox(height: 30),

            // Charts Section
            _buildChartsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thống Kê",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Tổng quan hiệu suất kinh doanh",
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<Map<String, dynamic>> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, i) {
        final s = stats[i];
        final Color color = s['color'] as Color;
        final List<Color> gradient = List<Color>.from(s['gradient'] as List);
        final IconData icon = s['icon'] as IconData;
        final String value = s['value'].toString();
        final String title = s['title'].toString();
        final Function()? route = s['route'] as Function()?;

        return GestureDetector(
          onTap: route,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (route != null)
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 14,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueByDateRangeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thống kê doanh thu theo khoảng thời gian",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          // 2 Date picker
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Từ ngày',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Chọn ngày bắt đầu',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đến ngày',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Chọn ngày kết thúc',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Nút thống kê
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startDate != null && _endDate != null
                  ? loadRevenueStatistics
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loadingRevenue
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          // Hiển thị kết quả (hiển thị sau khi đã load xong)
          if (_startDate != null && _endDate != null && !_loadingRevenue) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng doanh thu:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${formatCurrency(_revenueByDateRange)}₫',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng đơn hàng:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$_ordersByDateRange',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng khách hàng:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$_customersByDateRange',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Đơn thành công:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_donThanhCong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Đơn bị hủy:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_donBiHuy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Pie Chart - Phân bố trạng thái đơn hàng
            if (!_loadingStatusDistribution && _statusDistribution.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildStatusPieChart(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phân tích chi tiết",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Biểu đồ thể hiện hiệu suất kinh doanh",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        _buildRevenueChart(),
      ],
    );
  }

  Widget _buildRevenueChart() {
    // Tính maxY dựa trên dữ liệu thực tế
    double maxRevenue = 0;
    if (_monthlyRevenue.isNotEmpty) {
      maxRevenue = _monthlyRevenue
          .map((e) => (e['doanhThu'] as double))
          .reduce((a, b) => a > b ? a : b);
    }
    // Chuyển đổi sang triệu VNĐ và thêm 20% padding phía trên
    double maxY = (maxRevenue / 1000000) * 1.2;
    if (maxY == 0) maxY = 10; // Nếu không có dữ liệu, set mặc định 10 triệu

    // Chuyển đổi doanh thu từ VNĐ sang triệu VNĐ để hiển thị
    final barGroups = _monthlyRevenue.isEmpty
        ? List.generate(12, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: 0,
                  gradient: _createGradient([Colors.blue, Colors.lightBlue]),
                  borderRadius: BorderRadius.circular(4),
                  width: 16,
                )
              ],
            );
          })
        : _monthlyRevenue.asMap().entries.map((entry) {
            final index = entry.key;
            final monthData = entry.value;
            final revenue = monthData['doanhThu'] as double;
            final revenueInMillion = revenue / 1000000; // Chuyển sang triệu VNĐ

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: revenueInMillion,
                  gradient: _createGradient([Colors.blue, Colors.lightBlue]),
                  borderRadius: BorderRadius.circular(4),
                  width: 16,
                )
              ],
            );
          }).toList();

    // Tên các tháng
    const monthNames = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Doanh thu theo tháng",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              // Dropdown chọn năm
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        '$year',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                      });
                      loadMonthlyRevenue();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _loadingMonthlyRevenue
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.grey[800]!,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final monthIndex = group.x.toInt();
                            final monthName = monthNames[monthIndex];
                            final revenue = _monthlyRevenue.isNotEmpty &&
                                    monthIndex < _monthlyRevenue.length
                                ? (_monthlyRevenue[monthIndex]
                                        ['doanhThu'] as double)
                                : 0.0;
                            return BarTooltipItem(
                              '$monthName\n${formatCurrency(revenue)}₫',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < monthNames.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthNames[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, _) {
                              return Text(
                                '${value.toInt()}Tr',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
        ],
      ),
    );
  }


  LinearGradient _createGradient(List<Color> colors) {
    return LinearGradient(
      colors: colors,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  // Pie Chart - Phân bố trạng thái đơn hàng
  Widget _buildStatusPieChart() {
    if (_statusDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    // Màu sắc cho từng trạng thái
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
    ];

    // Tạo dữ liệu cho pie chart
    final pieChartSections = _statusDistribution.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data['percentage'] as num).toDouble();

      return PieChartSectionData(
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân loại đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 200,
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _statusDistribution.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final category = data['category'] as String;
                    final count = data['count'] as int;
                    final percentage = (data['percentage'] as num).toDouble();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Line Chart - Tăng trưởng đơn hàng theo tháng
  Widget _buildOrderGrowthLineChart() {
    // Tính maxY dựa trên dữ liệu
    double maxOrders = 0;
    if (_monthlyOrderGrowth.isNotEmpty) {
      maxOrders = _monthlyOrderGrowth
          .map((e) => (e['soDonHang'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
    }
    double maxY = maxOrders * 1.2;
    if (maxY == 0) maxY = 10;

    // Tạo dữ liệu cho line chart
    final lineSpots = _monthlyOrderGrowth.isEmpty
        ? List.generate(12, (index) => FlSpot(index.toDouble(), 0))
        : _monthlyOrderGrowth.asMap().entries.map((entry) {
            final index = entry.key;
            final monthData = entry.value;
            final soDonHang = (monthData['soDonHang'] as num).toDouble();
            return FlSpot(index.toDouble(), soDonHang);
          }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tăng trưởng đơn hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              // Year selector
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text('Năm $year'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedYear = value;
                    });
                    loadMonthlyOrderGrowth();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _loadingMonthlyOrderGrowth
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final monthNames = [
                                'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
                                'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
                              ];
                              if (value.toInt() >= 0 && value.toInt() < 12) {
                                return Text(
                                  monthNames[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: maxY,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
