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
    final salePrice = hasSale
        ? (originalPrice - _activeSale!.giaTriKhuyenMai).clamp(0.0, double.infinity)
        : originalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Giá cũ (gạch đỏ) - chỉ hiển thị khi có khuyến mãi
        if (hasSale && widget.showOriginalPrice)
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
        Text(
          '${_formatPrice(salePrice)}đ',
          style: TextStyle(
            fontSize: widget.fontSize ?? 14,
            fontWeight: FontWeight.bold,
            color: widget.priceColor ?? Colors.green,
          ),
        ),
      ],
    );
  }
}

