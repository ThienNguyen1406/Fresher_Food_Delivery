import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/qr_code_dialog.dart';
import 'package:fresher_food/roles/user/widgets/price_with_sale_widget.dart';
import 'package:fresher_food/utils/date_formatter.dart';

class ProductInfoCard extends StatelessWidget {
  final Product product;
  final ProductDetailProvider provider;

  const ProductInfoCard({
    super.key,
    required this.product,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.tenSanPham,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (provider.isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'Hết hàng',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (provider.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'Chỉ còn ${product.soLuongTon} sản phẩm',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (product.ngayHetHan != null)
                          _buildExpiryBadge(product.ngayHetHan!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // QR Code button
              GestureDetector(
                onTap: () => _showQRCodeDialog(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Favorite button
              GestureDetector(
                onTap: () => _toggleFavorite(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: provider.isFavorite
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: provider.isFavorite
                          ? Colors.red.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      provider.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: provider.isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                      key: ValueKey(provider.isFavorite),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.location_on_outlined,
                text: product.xuatXu,
              ),
              _buildInfoChip(
                icon: Icons.inventory_2_outlined,
                text: '${product.soLuongTon} ${product.donViTinh}',
              ),
              if (product.ngaySanXuat != null)
                _buildInfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: 'SX: ${DateFormatter.formatDate(product.ngaySanXuat!)}',
                ),
              if (product.ngayHetHan != null)
                _buildInfoChip(
                  icon: Icons.event_outlined,
                  text: 'HH: ${DateFormatter.formatDate(product.ngayHetHan!)}',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceWithSaleWidget(
                product: product,
                fontSize: 28,
                priceColor: provider.isOutOfStock
                    ? Colors.grey.shade400
                    : Colors.green.shade600,
              ),
              _buildRatingWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            provider.ratingStats.averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${provider.ratingStats.totalRatings})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    try {
      await provider.toggleFavorite(product.maSanPham);
    } catch (e) {
      // Handle error if needed
    }
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        productId: product.maSanPham,
        productName: product.tenSanPham,
      ),
    );
  }

  Widget _buildExpiryBadge(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    final isExpired = expiryDate.isBefore(now);
    final isNearExpiry = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isNearExpiry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
