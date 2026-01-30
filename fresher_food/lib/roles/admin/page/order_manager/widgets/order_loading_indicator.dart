import 'package:flutter/material.dart';

class OrderLoadingIndicator extends StatelessWidget {
  final Color primaryColor;
  final Color textLightColor;

  const OrderLoadingIndicator({
    super.key,
    required this.primaryColor,
    required this.textLightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              backgroundColor: primaryColor.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải đơn hàng...',
            style: TextStyle(
              color: textLightColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

