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
          if (!provider.isOutOfStock)
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
              child: ElevatedButton(
                onPressed: provider.isOutOfStock ? null : onAddToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: provider.isOutOfStock
                      ? Colors.grey.shade400
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: provider.isOutOfStock ? 0 : 4,
                  shadowColor: provider.isOutOfStock
                      ? Colors.transparent
                      : Colors.green.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        provider.isOutOfStock
                            ? Icons.inventory_2_outlined
                            : Icons.shopping_cart_outlined,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      provider.isOutOfStock ? "HẾT HÀNG" : "Thêm vào giỏ hàng",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
