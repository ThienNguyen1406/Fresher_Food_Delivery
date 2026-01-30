import 'package:flutter/material.dart';
import 'status_pie_chart.dart';

class RevenueByDateRangeSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool loadingRevenue;
  final double revenueByDateRange;
  final int ordersByDateRange;
  final int customersByDateRange;
  final int donThanhCong;
  final int donBiHuy;
  final bool loadingStatusDistribution;
  final List<Map<String, dynamic>> statusDistribution;
  final String Function(double) formatCurrency;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final VoidCallback onLoadStatistics;

  const RevenueByDateRangeSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.loadingRevenue,
    required this.revenueByDateRange,
    required this.ordersByDateRange,
    required this.customersByDateRange,
    required this.donThanhCong,
    required this.donBiHuy,
    required this.loadingStatusDistribution,
    required this.statusDistribution,
    required this.formatCurrency,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onLoadStatistics,
  });

  @override
  Widget build(BuildContext context) {
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
                child: _DatePickerField(
                  label: 'Từ ngày',
                  date: startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateSelected: onStartDateChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'Đến ngày',
                  date: endDate,
                  firstDate: startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateSelected: onEndDateChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Nút thống kê
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: startDate != null && endDate != null && !loadingRevenue
                  ? onLoadStatistics
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loadingRevenue
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
          // Hiển thị kết quả
          if (startDate != null && endDate != null && !loadingRevenue) ...[
            const SizedBox(height: 24),
            _RevenueResults(
              revenue: revenueByDateRange,
              orders: ordersByDateRange,
              customers: customersByDateRange,
              donThanhCong: donThanhCong,
              donBiHuy: donBiHuy,
              formatCurrency: formatCurrency,
            ),
            // Pie Chart - Phân bố trạng thái đơn hàng
            if (!loadingStatusDistribution && statusDistribution.isNotEmpty) ...[
              const SizedBox(height: 24),
              StatusPieChart(statusDistribution: statusDistribution),
            ],
          ],
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime?) onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        onDateSelected(selectedDate);
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
            Icon(Icons.calendar_today, color: Colors.grey[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date!.day}/${date!.month}/${date!.year}'
                        : label == 'Từ ngày' ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
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
    );
  }
}

class _RevenueResults extends StatelessWidget {
  final double revenue;
  final int orders;
  final int customers;
  final int donThanhCong;
  final int donBiHuy;
  final String Function(double) formatCurrency;

  const _RevenueResults({
    required this.revenue,
    required this.orders,
    required this.customers,
    required this.donThanhCong,
    required this.donBiHuy,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '${formatCurrency(revenue)}₫',
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '$orders',
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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '$customers',
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              Text(
                '$donThanhCong',
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              Text(
                '$donBiHuy',
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
    );
  }
}

