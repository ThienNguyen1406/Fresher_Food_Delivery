import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyRevenue;
  final int selectedYear;
  final bool loading;
  final String Function(double) formatCurrency;
  final Function(int) onYearChanged;

  const RevenueChart({
    super.key,
    required this.monthlyRevenue,
    required this.selectedYear,
    required this.loading,
    required this.formatCurrency,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Tính maxY dựa trên dữ liệu thực tế
    double maxRevenue = 0;
    if (monthlyRevenue.isNotEmpty) {
      maxRevenue = monthlyRevenue
          .map((e) => (e['doanhThu'] as double))
          .reduce((a, b) => a > b ? a : b);
    }
    // Chuyển đổi sang triệu VNĐ và thêm 20% padding phía trên
    double maxY = (maxRevenue / 1000000) * 1.2;
    if (maxY == 0) maxY = 10; // Nếu không có dữ liệu, set mặc định 10 triệu

    // Chuyển đổi doanh thu từ VNĐ sang triệu VNĐ để hiển thị
    final barGroups = monthlyRevenue.isEmpty
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
        : monthlyRevenue.asMap().entries.map((entry) {
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
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
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
                  value: selectedYear,
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
                      onYearChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          loading
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
                            final revenue = monthlyRevenue.isNotEmpty &&
                                    monthIndex < monthlyRevenue.length
                                ? (monthlyRevenue[monthIndex]['doanhThu'] as double)
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
}

