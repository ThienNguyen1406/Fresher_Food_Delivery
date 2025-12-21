import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/utils/date_formatter.dart';

class ProductDetailsSection extends StatelessWidget {
  final Product product;

  const ProductDetailsSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      icon: Icons.info_outline_rounded,
      title: "Thông tin chi tiết",
      child: Column(
        children: [
          _buildDetailRow("Xuất xứ", product.xuatXu),
          _buildDetailRow("Đơn vị tính", product.donViTinh),
          _buildDetailRow(
              "Số lượng tồn", "${product.soLuongTon} ${product.donViTinh}"),
          _buildDetailRow("Mã sản phẩm", product.maSanPham),
          if (product.ngaySanXuat != null)
            _buildDetailRow(
              "Ngày sản xuất",
              DateFormatter.formatDate(product.ngaySanXuat!),
            ),
          if (product.ngayHetHan != null)
            _buildDetailRowWithWarning(
              "Ngày hết hạn",
              DateFormatter.formatDate(product.ngayHetHan!),
              product.ngayHetHan!,
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithWarning(String label, String value, DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    final isExpired = expiryDate.isBefore(now);
    final isNearExpiry = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;

    Color textColor = Colors.black87;
    Widget? warningWidget;

    if (isExpired) {
      textColor = Colors.red.shade700;
      warningWidget = Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Đã hết hạn',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isNearExpiry) {
      textColor = Colors.orange.shade700;
      warningWidget = Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Còn $daysUntilExpiry ngày',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (warningWidget != null) warningWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

}
