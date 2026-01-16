import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/roles/user/widgets/price_with_sale_widget.dart';
import 'package:fresher_food/utils/date_formatter.dart';
import 'package:fresher_food/roles/user/home/widgets/home_snackbar_widgets.dart';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final HomeProvider provider;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        provider.state.favoriteProductIds.contains(product.maSanPham);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppRoute.toProductDetail(context, product.maSanPham);
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Builder(
                        builder: (context) {
                          final isExpired = product.ngayHetHan != null && 
                              product.ngayHetHan!.isBefore(DateTime.now());
                          return Stack(
                            children: [
                              Image.network(
                                product.anh,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.green,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey, size: 40),
                                ),
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Gạch chéo khi hết hàng hoặc hết hạn
                              if (product.soLuongTon <= 0 || isExpired)
                                CustomPaint(
                                  painter: DiagonalLinePainter(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              // Badge "Sản phẩm hết hạn"
                              if (isExpired && product.soLuongTon > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'HẾT HẠN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Product Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Product Name
                                Text(
                                  product.tenSanPham,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),

                                // Origin
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        product.xuatXu,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),

                                // Stock
                                Text(
                                  "Còn: ${product.soLuongTon} sp",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: product.soLuongTon > 0
                                        ? Colors.grey.shade600
                                        : Colors.red,
                                    fontWeight: product.soLuongTon > 0
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                // Production Date and Expiry Date - gộp trên 1 dòng để tiết kiệm không gian
                                if (product.ngaySanXuat != null || product.ngayHetHan != null) ...[
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 2,
                                    children: [
                                      if (product.ngaySanXuat != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 9,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              "SX: ${DateFormatter.formatDate(product.ngaySanXuat!)}",
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (product.ngayHetHan != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getExpiryIcon(product.ngayHetHan!),
                                              size: 9,
                                              color: _getExpiryColor(product.ngayHetHan!),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              "HH: ${DateFormatter.formatDate(product.ngayHetHan!)}",
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: _getExpiryColor(product.ngayHetHan!),
                                                fontWeight: _isExpiredOrNearExpiry(product.ngayHetHan!)
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Price and Add Button
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: PriceWithSaleWidget(
                                    product: product,
                                    fontSize: 13,
                                    priceColor: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Add Button
                                Builder(
                                  builder: (context) {
                                    final isExpired = product.ngayHetHan != null && 
                                        product.ngayHetHan!.isBefore(DateTime.now());
                                    final canAddToCart = product.soLuongTon > 0 && !isExpired;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: canAddToCart
                                            ? Colors.green
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                        boxShadow: canAddToCart
                                            ? [
                                                BoxShadow(
                                                  color:
                                                      Colors.green.withOpacity(0.4),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: canAddToCart
                                              ? () => _handleAddToCart(context, product, provider)
                                              : null,
                                          borderRadius: BorderRadius.circular(16),
                                          child: Icon(
                                            canAddToCart
                                                ? Icons.add
                                                : Icons.remove_shopping_cart,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Favorite Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => provider.toggleFavorite(product),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Out of stock badge
              if (product.soLuongTon <= 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'HẾT HÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method để lấy icon cho ngày hết hạn
  IconData _getExpiryIcon(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    final isExpired = expiryDate.isBefore(now);
    
    if (isExpired) {
      return Icons.warning_amber_rounded;
    } else if (daysUntilExpiry <= 7) {
      return Icons.schedule;
    } else {
      return Icons.event_outlined;
    }
  }

  // Helper method để lấy màu cho ngày hết hạn
  Color _getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    final isExpired = expiryDate.isBefore(now);
    
    if (isExpired) {
      return Colors.red.shade700;
    } else if (daysUntilExpiry <= 7) {
      return Colors.orange.shade700;
    } else {
      return Colors.grey.shade600;
    }
  }

  // Helper method để kiểm tra sản phẩm sắp hết hạn hoặc đã hết hạn
  bool _isExpiredOrNearExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return expiryDate.isBefore(now) || daysUntilExpiry <= 7;
  }

  // Handler để thêm vào giỏ hàng với thông báo
  Future<void> _handleAddToCart(BuildContext context, Product product, HomeProvider provider) async {
    try {
      final success = await provider.addToCart(product);
      if (success) {
        HomeSnackbarWidgets.showSuccess(
          context,
          'Đã thêm "${product.tenSanPham}" vào giỏ hàng',
        );
      }
    } catch (e) {
      if (e.toString().contains('đăng nhập')) {
        HomeSnackbarWidgets.showLoginRequired(context);
      } else {
        HomeSnackbarWidgets.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }
}

// Custom Painter để vẽ đường gạch chéo
class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Vẽ đường gạch chéo từ góc trên trái đến góc dưới phải
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

