import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OrderGrowthLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyOrderGrowth;
  final int selectedYear;
  final bool loading;
  final Function(int) onYearChanged;

  const OrderGrowthLineChart({
    super.key,
    required this.monthlyOrderGrowth,
    required this.selectedYear,
    required this.loading,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Tính maxY dựa trên dữ liệu
    double maxOrders = 0;
    if (monthlyOrderGrowth.isNotEmpty) {
      maxOrders = monthlyOrderGrowth
          .map((e) => (e['soDonHang'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
    }
    double maxY = maxOrders * 1.2;
    if (maxY == 0) maxY = 10;

    // Tạo dữ liệu cho line chart
    final lineSpots = monthlyOrderGrowth.isEmpty
        ? List.generate(12, (index) => FlSpot(index.toDouble(), 0))
        : monthlyOrderGrowth.asMap().entries.map((entry) {
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
                value: selectedYear,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text('Năm $year'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    onYearChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: loading
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
                              const monthNames = [
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

