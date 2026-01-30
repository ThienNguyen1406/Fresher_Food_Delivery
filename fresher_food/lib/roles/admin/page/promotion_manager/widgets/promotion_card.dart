import 'package:flutter/material.dart';
import 'package:fresher_food/models/Sale.dart';
import 'package:intl/intl.dart';

class PromotionCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color errorColor;

  const PromotionCard({
    super.key,
    required this.sale,
    required this.onEdit,
    required this.onDelete,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.errorColor,
  });

  Color _getStatusColor() {
    if (sale.isExpired) return textSecondary;
    if (sale.isActive) return const Color(0xFF10B981);
    if (sale.isUpcoming) return const Color(0xFFF59E0B);
    return textSecondary;
  }

  String _getStatusText() {
    if (sale.isExpired) return 'Đã hết hạn';
    if (sale.isActive) return 'Đang hoạt động';
    if (sale.isUpcoming) return 'Sắp diễn ra';
    return 'Không hoạt động';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public,
                                      size: 14, color: Colors.orange.shade700),
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
                                color: textPrimary,
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
                            color: textSecondary,
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
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  sale.loaiGiaTri == 'Percent'
                      ? '${sale.giaTriKhuyenMai.toStringAsFixed(0)}%'
                      : '${NumberFormat('#,###').format(sale.giaTriKhuyenMai.toInt())} VNĐ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
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
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: textSecondary.withOpacity(0.2)),
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
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.ngayBatDau),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
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
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.ngayKetThuc),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
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
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: errorColor,
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

