import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';

class PaymentOptionWidget extends StatelessWidget {
  final CheckoutProvider provider;
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final Color textPrimary;
  final Color textSecondary;
  final Color backgroundColor;

  const PaymentOptionWidget({
    super.key,
    required this.provider,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: provider.selectedPaymentId,
        onChanged: (value) {
          String paymentMethod = 'cod'; // Mặc định là COD
          final payName = title.toLowerCase();
          
          // Kiểm tra COD trước (thanh toán khi nhận hàng)
          if (payName.contains('cod') || 
              payName.contains('tiền mặt') || 
              payName.contains('khi nhận hàng') ||
              payName.contains('thanh toán khi nhận')) {
            paymentMethod = 'cod';
          } 
          // Kiểm tra chuyển khoản ngân hàng
          else if (payName.contains('banking') || 
                   payName.contains('bank') || 
                   payName.contains('chuyển khoản') || 
                   payName.contains('transfer') ||
                   payName.contains('ngân hàng')) {
            paymentMethod = 'banking';
          } 
          // Kiểm tra MoMo
          else if (payName.contains('momo')) {
            paymentMethod = 'momo';
          } 
          // Kiểm tra Stripe/Card
          else if (payName.contains('stripe') || 
                   payName.contains('thẻ') || 
                   payName.contains('card') || 
                   payName.contains('credit') ||
                   payName.contains('debit')) {
            paymentMethod = 'stripe';
          }
          // Mặc định là COD nếu không match
          
          print('Payment method được chọn: $paymentMethod (từ title: $title)');
          provider.updatePaymentMethod(paymentMethod, value!);
        },
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? color.withOpacity(0.8) : textSecondary,
            fontSize: 13,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : textSecondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : textSecondary,
            size: 20,
          ),
        ),
        activeColor: color,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

