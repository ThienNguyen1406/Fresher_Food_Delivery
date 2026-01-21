import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:iconsax/iconsax.dart';

class ProductGridItemWidget extends StatelessWidget {
  final Product product;
  final Function(Product)? onTap;
  final String Function(double) formatPrice;

  const ProductGridItemWidget({
    super.key,
    required this.product,
    this.onTap,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null ? () => onTap!(product) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hình ảnh sản phẩm
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: const Color(0xFFE8F5E8),
              image: product.anh.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.anh),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.anh.isEmpty
                ? const Center(
                    child: Icon(Iconsax.box, color: Color(0xFF2E7D32), size: 48),
                  )
                : null,
          ),
          // Thông tin sản phẩm - chỉ giá và số lượng trong 1 hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Giá - nổi bật
                Expanded(
                  child: Text(
                    formatPrice(product.giaBan),
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                // Số lượng
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.box_1, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${product.soLuongTon} ${product.donViTinh}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
  }
}

