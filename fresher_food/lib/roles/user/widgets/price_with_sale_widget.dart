import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Sale.dart';
import 'package:fresher_food/services/api/sale_api.dart';

class PriceWithSaleWidget extends StatefulWidget {
  final Product product;
  final double? fontSize;
  final Color? priceColor;
  final bool showOriginalPrice;

  const PriceWithSaleWidget({
    super.key,
    required this.product,
    this.fontSize,
    this.priceColor,
    this.showOriginalPrice = true,
  });

  @override
  State<PriceWithSaleWidget> createState() => _PriceWithSaleWidgetState();
}

class _PriceWithSaleWidgetState extends State<PriceWithSaleWidget> {
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
      final productSales = await _saleApi.getSalesByProduct(widget.product.maSanPham);
      
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Kiểm tra sản phẩm có gần hết hạn không (≤ 7 ngày)
  bool _isNearExpiry(Product product) {
    if (product.ngayHetHan == null) return false;
    
    final now = DateTime.now();
    final expiryDate = product.ngayHetHan!;
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    
    // Gần hết hạn nếu còn từ 0 đến 7 ngày (chưa hết hạn)
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
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

    final originalPrice = widget.product.giaBan;
    final hasSale = _activeSale != null;
    
    // Kiểm tra nếu sản phẩm gần hết hạn (≤ 7 ngày) thì tự động giảm 30%
    final isNearExpiry = _isNearExpiry(widget.product);
    final expiryDiscount = isNearExpiry ? originalPrice * 0.3 : 0.0;
    
    // Tính giá sau khuyến mãi (ưu tiên khuyến mãi từ Sale, sau đó mới đến giảm giá hết hạn)
    double salePrice = originalPrice;
    if (hasSale) {
      salePrice = (originalPrice - _activeSale!.giaTriKhuyenMai).clamp(0.0, double.infinity);
    } else if (isNearExpiry) {
      salePrice = (originalPrice - expiryDiscount).clamp(0.0, double.infinity);
    }
    
    final hasAnyDiscount = hasSale || isNearExpiry;

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
