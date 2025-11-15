import 'package:flutter/material.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';

class CouponItemWidget extends StatelessWidget {
  final CheckoutProvider provider;
  final PhieuGiamGia coupon;
  final bool isSelected;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CouponItemWidget({
    super.key,
    required this.provider,
    required this.coupon,
    required this.isSelected,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : textSecondary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : textSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.discount_outlined,
                  color: isSelected ? Colors.white : textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primaryColor : textPrimary,
                      ),
                    ),
                    if (coupon.moTa.isNotEmpty)
                      Text(
                        coupon.moTa,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? primaryColor.withOpacity(0.8) : textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Giảm ${provider.formatPrice(coupon.giaTri)}đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : textSecondary.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isSelected ? primaryColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

