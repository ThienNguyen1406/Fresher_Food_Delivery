import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/payment_option_widget.dart';

class PaymentMethodSection extends StatelessWidget {
  final CheckoutProvider provider;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  const PaymentMethodSection({
    super.key,
    required this.provider,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: provider.paymentMethods.map((pay) {
          final isSelected = provider.selectedPaymentId == pay.Id_Pay;
          final payName = pay.Pay_name.toLowerCase();
          final isCOD = payName.contains('cod');
          final isMoMo = payName.contains('momo');
          final isStripe = payName.contains('stripe') || payName.contains('thẻ') || payName.contains('card') || payName.contains('credit');
          final isBanking = payName.contains('banking') || payName.contains('bank') || payName.contains('chuyển khoản') || payName.contains('transfer');

          IconData icon;
          Color color;
          String subtitle;

          if (isCOD) {
            icon = Icons.money_outlined;
            color = primaryColor;
            subtitle = 'Thanh toán bằng tiền mặt khi nhận hàng';
          } else if (isMoMo) {
            icon = Icons.phone_iphone_outlined;
            color = Colors.pink;
            subtitle = 'Thanh toán qua ứng dụng MoMo';
          } else if (isStripe) {
            icon = Icons.credit_card;
            color = Colors.blue;
            subtitle = 'Thanh toán bằng thẻ tín dụng/ghi nợ';
          } else if (isBanking) {
            icon = Icons.account_balance;
            color = Colors.purple;
            subtitle = 'Chuyển khoản qua ngân hàng';
          } else {
            icon = Icons.account_balance_outlined;
            color = accentColor;
            subtitle = pay.Pay_name.isNotEmpty
                ? 'Thanh toán qua ${pay.Pay_name}'
                : 'Thanh toán trực tuyến';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaymentOptionWidget(
              provider: provider,
              value: pay.Id_Pay,
              title: pay.Pay_name.isNotEmpty ? pay.Pay_name : 'Thanh toán trực tuyến',
              subtitle: subtitle,
              icon: icon,
              color: color,
              isSelected: isSelected,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              backgroundColor: backgroundColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}

