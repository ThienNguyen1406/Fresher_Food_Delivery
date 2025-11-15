import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/coupon_item_widget.dart';

class CouponSelectionDialog extends StatelessWidget {
  final CheckoutProvider provider;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color backgroundColor;
  final Color surfaceColor;

  const CouponSelectionDialog({
    super.key,
    required this.provider,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.discount_outlined,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.state.availableCoupons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            color: textSecondary.withOpacity(0.5),
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không có mã giảm giá nào',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.state.availableCoupons.length,
                      itemBuilder: (context, index) {
                        final coupon = provider.state.availableCoupons[index];
                        final isSelected = provider.selectedCoupon?.idPhieuGiamGia == coupon.idPhieuGiamGia;
                        return CouponItemWidget(
                          provider: provider,
                          coupon: coupon,
                          isSelected: isSelected,
                          primaryColor: primaryColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          backgroundColor: backgroundColor,
                          onTap: () {
                            provider.applyCoupon(coupon);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã áp dụng mã giảm giá ${coupon.code}'),
                                backgroundColor: primaryColor,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: textSecondary.withOpacity(0.3)),
                      ),
                      child: const Text('HỦY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('XONG'),
                    ),
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

