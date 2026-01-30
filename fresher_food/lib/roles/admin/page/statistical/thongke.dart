import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/services/api/order_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/admin/page/order_manager/quanlydonhang.dart';
import 'package:fresher_food/roles/admin/page/user_manager/quanlynguoidung.dart';
import 'package:fresher_food/roles/admin/page/product_manager/quanlysanpham.dart';
import 'package:fresher_food/services/api/statistics_api.dart';
import 'widgets/statistics_header.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/revenue_by_date_range_section.dart';
import 'widgets/charts_section.dart';
import 'widgets/order_growth_line_chart.dart';

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
          ' Loading revenue statistics from ${_startDate!.toIso8601String().split('T')[0]} to ${_endDate!.toIso8601String().split('T')[0]}');

      final statistics = await OrderApi().getRevenueStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );

      print(' Statistics received: $statistics');

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
          ' Final values: Revenue=${_revenueByDateRange}, Orders=${_ordersByDateRange}, Customers=${_customersByDateRange}');
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
      print(' Loading monthly revenue for year: $_selectedYear');
      final monthlyData =
          await OrderApi().getMonthlyRevenue(year: _selectedYear);

      setState(() {
        _monthlyRevenue = monthlyData;
        _loadingMonthlyRevenue = false;
      });

      print(' Monthly revenue loaded: ${_monthlyRevenue.length} months');
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
      final growth =
          await OrderApi().getMonthlyOrderGrowth(year: _selectedYear);

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
            StatisticsHeader(
              isExporting: _isExporting,
              onExport: _exportToExcel,
            ),
            const SizedBox(height: 20),

            // Statistics Cards
            StatisticsGrid(stats: stats),
            const SizedBox(height: 30),

            // Thống kê doanh thu theo khoảng thời gian
            RevenueByDateRangeSection(
              startDate: _startDate,
              endDate: _endDate,
              loadingRevenue: _loadingRevenue,
              revenueByDateRange: _revenueByDateRange,
              ordersByDateRange: _ordersByDateRange,
              customersByDateRange: _customersByDateRange,
              donThanhCong: _donThanhCong,
              donBiHuy: _donBiHuy,
              loadingStatusDistribution: _loadingStatusDistribution,
              statusDistribution: _statusDistribution,
              formatCurrency: formatCurrency,
              onStartDateChanged: (date) {
                setState(() {
                  _startDate = date;
                });
              },
              onEndDateChanged: (date) {
                setState(() {
                  _endDate = date;
                });
              },
              onLoadStatistics: loadRevenueStatistics,
            ),
            const SizedBox(height: 30),

            // Line Chart - Tăng trưởng đơn hàng theo tháng
            OrderGrowthLineChart(
              monthlyOrderGrowth: _monthlyOrderGrowth,
              selectedYear: _selectedYear,
              loading: _loadingMonthlyOrderGrowth,
              onYearChanged: (year) {
                setState(() {
                  _selectedYear = year;
                });
                loadMonthlyOrderGrowth();
              },
            ),
            const SizedBox(height: 30),

            // Charts Section
            ChartsSection(
              monthlyRevenue: _monthlyRevenue,
              selectedYear: _selectedYear,
              loadingMonthlyRevenue: _loadingMonthlyRevenue,
              formatCurrency: formatCurrency,
              onYearChanged: (year) {
                setState(() {
                  _selectedYear = year;
                });
                loadMonthlyRevenue();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isExporting = false;

  final StatisticsApi _statisticsApi = StatisticsApi();

  Future<void> _exportToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _statisticsApi.exportToExcel(
        year: _selectedYear,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        final success = result['success'] as bool;
        final filePath = result['filePath'] as String?;
        final fileName = result['fileName'] as String?;
        final error = result['error'] as String?;

        if (success && filePath != null) {
          final fileSize = result['fileSize'] as int?;
          final fileSizeMB = fileSize != null
              ? (fileSize / 1024 / 1024).toStringAsFixed(2)
              : 'N/A';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Xuất báo cáo Excel thành công!'),
                  const SizedBox(height: 4),
                  Text(
                    'File: $fileName',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (fileSize != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Kích thước: ${fileSizeMB} MB',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Xem đường dẫn',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Thông tin file'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Tên file:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(fileName ?? 'N/A'),
                            const SizedBox(height: 12),
                            const Text('Đường dẫn:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(filePath),
                            if (fileSize != null) ...[
                              const SizedBox(height: 12),
                              Text('Kích thước: ${fileSizeMB} MB',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❌ Xuất báo cáo thất bại'),
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất báo cáo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
