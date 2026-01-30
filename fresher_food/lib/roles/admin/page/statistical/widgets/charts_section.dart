import 'package:flutter/material.dart';
import 'revenue_chart.dart';

class ChartsSection extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyRevenue;
  final int selectedYear;
  final bool loadingMonthlyRevenue;
  final String Function(double) formatCurrency;
  final Function(int) onYearChanged;

  const ChartsSection({
    super.key,
    required this.monthlyRevenue,
    required this.selectedYear,
    required this.loadingMonthlyRevenue,
    required this.formatCurrency,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        RevenueChart(
          monthlyRevenue: monthlyRevenue,
          selectedYear: selectedYear,
          loading: loadingMonthlyRevenue,
          formatCurrency: formatCurrency,
          onYearChanged: onYearChanged,
        ),
      ],
    );
  }
}

