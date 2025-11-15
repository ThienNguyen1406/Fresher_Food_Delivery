import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider provider;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem) onDelete;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.provider,
    required this.onUpdateQuantity,
    required this.onDelete,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.'
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = cartItem.soLuongTon == 0;
    final isLowStock = cartItem.soLuong > cartItem.soLuongTon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: isOutOfStock || isLowStock
            ? Border.all(color: Colors.orange.shade300, width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox chọn sản phẩm
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: cartItem.isSelected ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Checkbox(
                    value: cartItem.isSelected && !isOutOfStock,
                    onChanged: isOutOfStock
                        ? null
                        : (value) => provider.toggleItemSelection(cartItem.maSanPham, value),
                    activeColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),

                // Ảnh sản phẩm
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    image: cartItem.anh.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(cartItem.anh),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cartItem.anh.isEmpty
                      ? Center(
                          child: Text(
                            cartItem.tenSanPham.isNotEmpty ? cartItem.tenSanPham[0] : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : null,
                ),

                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cartItem.tenSanPham,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatPrice(cartItem.giaBan)}đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                      // Hiển thị cảnh báo số lượng tồn kho
                      if (isOutOfStock)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'Hết hàng',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (isLowStock)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Chỉ còn ${cartItem.soLuongTon} sản phẩm',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Bộ chọn số lượng
                      Container(
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade100 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove,
                                  size: 18,
                                  color: isOutOfStock ? Colors.grey.shade400 : Colors.grey.shade600),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: isOutOfStock
                                  ? null
                                  : () => onUpdateQuantity(cartItem, cartItem.soLuong - 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cartItem.soLuong}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock ? Colors.grey.shade400 : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  size: 18,
                                  color: isOutOfStock ? Colors.grey.shade400 : Colors.green.shade600),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: isOutOfStock
                                  ? null
                                  : () => onUpdateQuantity(cartItem, cartItem.soLuong + 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tổng tiền và nút xóa
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(cartItem.thanhTien)}đ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                        padding: EdgeInsets.zero,
                        onPressed: () => onDelete(cartItem),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

