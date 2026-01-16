import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';

class ProductBottomActionBar extends StatelessWidget {
  final ProductDetailProvider provider;
  final AnimationController addToCartController;
  final Animation<double> scaleAnimation;
  final VoidCallback onAddToCart;

  const ProductBottomActionBar({
    super.key,
    required this.provider,
    required this.addToCartController,
    required this.scaleAnimation,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (provider.canAddToCart)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_rounded,
                      color: provider.quantity > 1
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    onPressed: provider.decreaseQuantity,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      "${provider.quantity}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_rounded,
                      color: provider.quantity < provider.product!.soLuongTon
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                    ),
                    onPressed: provider.increaseQuantity,
                  ),
                ],
              ),
            ),
          if (!provider.isOutOfStock) const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: addToCartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: scaleAnimation.value,
                  child: child,
                );
              },
              child: Builder(
                builder: (context) {
                  final canAddToCart = provider.canAddToCart;
                  return ElevatedButton(
                    onPressed: canAddToCart ? onAddToCart : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: canAddToCart
                          ? Colors.green.shade600
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: canAddToCart ? 4 : 0,
                      shadowColor: canAddToCart
                          ? Colors.green.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            canAddToCart
                                ? Icons.shopping_cart_outlined
                                : (provider.isOutOfStock
                                    ? Icons.inventory_2_outlined
                                    : Icons.warning_amber_rounded),
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          canAddToCart
                              ? "Thêm vào giỏ hàng"
                              : (provider.isOutOfStock
                                  ? "HẾT HÀNG"
                                  : "SẢN PHẨM HẾT HẠN"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
