import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/models/Sale.dart';
import 'package:fresher_food/services/api/sale_api.dart';

class CartPriceWithSaleWidget extends StatefulWidget {
  final CartItem cartItem;
  final double? fontSize;
  final Color? priceColor;
  final bool showOriginalPrice;

  const CartPriceWithSaleWidget({
    super.key,
    required this.cartItem,
    this.fontSize,
    this.priceColor,
    this.showOriginalPrice = true,
  });

  @override
  State<CartPriceWithSaleWidget> createState() => _CartPriceWithSaleWidgetState();
}

class _CartPriceWithSaleWidgetState extends State<CartPriceWithSaleWidget> {
  Sale? _activeSale;
  bool _isLoading = true;
  final SaleApi _saleApi = SaleApi();

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    try {
      final now = DateTime.now();
      
      // Lấy khuyến mãi cho sản phẩm cụ thể
      final productSales = await _saleApi.getSalesByProduct(widget.cartItem.maSanPham);
      
      // Lấy khuyến mãi toàn bộ sản phẩm (ALL)
      final allSales = await _saleApi.getSalesByProduct('ALL');
      
      // Tìm khuyến mãi đang hoạt động (Active và trong khoảng thời gian)
      // Ưu tiên khuyến mãi cho sản phẩm cụ thể trước
      Sale? activeSale;
      
      // Tìm khuyến mãi cho sản phẩm cụ thể trước
      try {
        activeSale = productSales.firstWhere(
          (sale) => sale.trangThai == 'Active' &&
              now.isAfter(sale.ngayBatDau) &&
              now.isBefore(sale.ngayKetThuc),
        );
      } catch (e) {
        // Không tìm thấy khuyến mãi cho sản phẩm cụ thể, tìm khuyến mãi toàn bộ
        try {
          activeSale = allSales.firstWhere(
            (sale) => sale.trangThai == 'Active' &&
                now.isAfter(sale.ngayBatDau) &&
                now.isBefore(sale.ngayKetThuc),
          );
        } catch (e) {
          activeSale = null;
        }
      }

      if (mounted) {
        setState(() {
          _activeSale = activeSale;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Kiểm tra sản phẩm có gần hết hạn không (≤ 7 ngày)
  bool _isNearExpiry(CartItem cartItem) {
    if (cartItem.ngayHetHan == null) return false;
    
    final now = DateTime.now();
    final expiryDate = cartItem.ngayHetHan!;
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    
    // Gần hết hạn nếu còn từ 0 đến 7 ngày (chưa hết hạn)
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.fontSize ?? 14,
        width: 60,
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final originalPrice = widget.cartItem.giaBan;
    final hasSale = _activeSale != null;
    
    // Tính giá sau khuyến mãi
    // QUY TẮC: Nếu sản phẩm đã có Sale (khuyến mãi) thì CHỈ áp dụng Sale, KHÔNG áp dụng giảm giá hết hạn
    // Nếu không có Sale, mới kiểm tra giảm giá hết hạn (30% nếu còn ≤ 7 ngày)
    double salePrice = originalPrice;
    bool hasAnyDiscount = false;
    bool isNearExpiry = false;
    
    if (hasSale) {
      // Có Sale -> CHỈ áp dụng Sale, KHÔNG áp dụng giảm giá hết hạn
      final sale = _activeSale!;
      if (sale.loaiGiaTri == 'Percent') {
        // Giảm giá theo phần trăm: giá mới = giá gốc * (1 - phần trăm / 100)
        // Ví dụ: giảm 15% -> giá mới = giá gốc * (1 - 15/100) = giá gốc * 0.85
        final phanTramGiam = sale.giaTriKhuyenMai / 100.0;
        final soTienGiam = originalPrice * phanTramGiam;
        salePrice = (originalPrice - soTienGiam).clamp(0.0, double.infinity);
      } else {
        // Giảm giá theo số tiền cố định: giá mới = giá gốc - số tiền giảm
        salePrice = (originalPrice - sale.giaTriKhuyenMai).clamp(0.0, double.infinity);
      }
      hasAnyDiscount = true;
    } else {
      // Không có Sale -> mới kiểm tra giảm giá hết hạn (30% nếu còn ≤ 7 ngày)
      isNearExpiry = _isNearExpiry(widget.cartItem);
      if (isNearExpiry) {
        final expiryDiscount = originalPrice * 0.3;
        salePrice = (originalPrice - expiryDiscount).clamp(0.0, double.infinity);
        hasAnyDiscount = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Giá cũ (gạch đỏ) - hiển thị khi có khuyến mãi hoặc giảm giá hết hạn
        if (hasAnyDiscount && widget.showOriginalPrice)
          Text(
            '${_formatPrice(originalPrice)}đ',
            style: TextStyle(
              fontSize: (widget.fontSize ?? 14) - 2,
              color: Colors.red,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red,
              decorationThickness: 2,
            ),
          ),
        // Giá mới (giá sau khuyến mãi)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_formatPrice(salePrice)}đ',
              style: TextStyle(
                fontSize: widget.fontSize ?? 14,
                fontWeight: FontWeight.bold,
                color: widget.priceColor ?? Colors.green,
              ),
            ),
            // Badge giảm giá hết hạn
            if (isNearExpiry && !hasSale)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200, width: 0.5),
                ),
                child: Text(
                  '-30%',
                  style: TextStyle(
                    fontSize: (widget.fontSize ?? 14) - 4,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

