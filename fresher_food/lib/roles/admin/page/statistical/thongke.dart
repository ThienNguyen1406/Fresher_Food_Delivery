import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/admin/page/order_manager/quanlydonhang.dart';
import 'package:fresher_food/roles/admin/page/user_manager/quanlynguoidung.dart';
import 'package:fresher_food/roles/admin/page/product_manager/quanlysanpham.dart';

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  // final ApiService apiService = ApiService();

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

  // Thống kê doanh thu theo tháng
  List<Map<String, dynamic>> _monthlyRevenue = [];
  bool _loadingMonthlyRevenue = false;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadStats();
    loadMonthlyRevenue();
  }

  Future<void> loadStats() async {
    setState(() => _loading = true);
    try {
      // 1. Tổng đơn hàng và doanh thu
      final donHangs = await OrderApi().getOrders();
      tongDonHang = donHangs.length;

      // Lấy tất cả order details và tính doanh thu
      allOrderDetails = [];
      for (var donHang in donHangs) {
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

      // Tính tổng doanh thu từ order details
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

  // Load thống kê doanh thu theo khoảng thời gian
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
        _loadingRevenue = false;
      });

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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        const SizedBox(height: 24),
        _buildOrderTypeChart(),
        const SizedBox(height: 24),
        _buildUserGrowthChart(),
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

  Widget _buildOrderTypeChart() {
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
          Text(
            "Phân loại đơn hàng",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue,
                          value: 35,
                          title: '35%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: 25,
                          title: '25%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: 20,
                          title: '20%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.purple,
                          value: 20,
                          title: '20%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("Đơn Online", Colors.blue),
                      _buildLegendItem("Đơn tại quán", Colors.green),
                      _buildLegendItem("Đơn mang về", Colors.orange),
                      _buildLegendItem("Đơn giao hàng", Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
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
                "Tăng trưởng người dùng",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "+8.2%",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const months = ['T5', 'T6', 'T7', 'T8', 'T9', 'T10'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 6),
                      FlSpot(3, 8),
                      FlSpot(4, 10),
                      FlSpot(5, 12),
                    ],
                    isCurved: true,
                    gradient: _createGradient([Colors.orange, Colors.amber]),
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: _createGradient([
                        Colors.orange.withOpacity(0.3),
                        Colors.amber.withOpacity(0.1),
                      ]),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
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
}
