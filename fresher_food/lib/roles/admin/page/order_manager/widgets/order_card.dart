import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:iconsax/iconsax.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Map<String, String> statusMap;
  final Map<String, Color> statusColorMap;
  final Function(Order) onViewDetail;
  final Function(Order) onUpdateStatus;
  final String Function(DateTime) formatDate;
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textLightColor;

  const OrderCard({
    super.key,
    required this.order,
    required this.statusMap,
    required this.statusColorMap,
    required this.onViewDetail,
    required this.onUpdateStatus,
    required this.formatDate,
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textLightColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = statusMap[order.trangThai] ?? 'Không xác định';
    final statusColor = statusColorMap[order.trangThai] ?? Colors.grey;
    final canEdit = order.trangThai != 'completed' && order.trangThai != 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
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
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.maDonHang,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor,
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
                Icon(Iconsax.profile_circle, size: 16, color: textLightColor),
                const SizedBox(width: 8),
                Text(
                  'Mã TK: ${order.maTaiKhoan}',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.call, size: 16, color: textLightColor),
                const SizedBox(width: 8),
                Text(
                  order.soDienThoai ?? 'Chưa có SĐT',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Thông tin đơn hàng
            Row(
              children: [
                Icon(Iconsax.calendar, size: 16, color: textLightColor),
                const SizedBox(width: 8),
                Text(
                  'Ngày: ${formatDate(order.ngayDat)}',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),

            // Địa chỉ giao hàng
            if (order.diaChiGiaoHang != null && order.diaChiGiaoHang!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.location, size: 16, color: textLightColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.diaChiGiaoHang!,
                      style: TextStyle(
                        color: textLightColor,
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
                        color: primaryColor,
                      ),
                    ),
                    if (order.phuongThucThanhToan != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'PTTT: ${order.phuongThucThanhToan}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textLightColor,
                        ),
                      ),
                    ]
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Iconsax.eye, size: 20, color: accentColor),
                        onPressed: () => onViewDetail(order),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: canEdit
                            ? primaryColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Iconsax.edit,
                          size: 20,
                          color: canEdit ? primaryColor : Colors.grey,
                        ),
                        onPressed: canEdit ? () => onUpdateStatus(order) : null,
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
}

