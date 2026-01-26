import 'package:flutter/material.dart';

/// Widget hiển thị card preview real-time
class CardPreview extends StatelessWidget {
  final String? cardNumber;
  final String? cardholderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? brand; // visa, mastercard, amex, etc.

  const CardPreview({
    super.key,
    this.cardNumber,
    this.cardholderName,
    this.expiryMonth,
    this.expiryYear,
    this.brand,
  });

  String _formatCardNumber(String? number) {
    if (number == null || number.isEmpty) {
      return '•••• •••• •••• ••••';
    }
    // Loại bỏ khoảng trắng và chỉ lấy số
    final cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    // Format: XXXX XXXX XXXX XXXX
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    // Thêm • cho các số còn thiếu
    while (buffer.length < 19) {
      if (buffer.length > 0 && buffer.toString().split(' ').last.length == 4) {
        buffer.write(' ');
      }
      buffer.write('•');
    }
    return buffer.toString();
  }

  String _getBrandLogo(String? brand) {
    if (brand == null) return 'visa';
    final b = brand.toLowerCase();
    if (b.contains('visa')) return 'visa';
    if (b.contains('master')) return 'mastercard';
    if (b.contains('amex') || b.contains('american')) return 'amex';
    if (b.contains('discover')) return 'discover';
    return 'visa';
  }

  @override
  Widget build(BuildContext context) {
    final formattedNumber = _formatCardNumber(cardNumber);
    final displayName = cardholderName ?? 'CARDHOLDER NAME';
    final expiry = '${expiryMonth ?? 'MM'}/${expiryYear ?? 'YY'}';
    final brandLogo = _getBrandLogo(brand);

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B46C1), // Purple
            const Color(0xFFEC4899), // Magenta
            const Color(0xFFF97316), // Orange
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Card name and brand logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông tin thẻ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                // Brand logo placeholder
                Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      brandLogo == 'mastercard'
                          ? 'MC'
                          : brandLogo.toUpperCase().substring(0, 1),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Card number
            Text(
              formattedNumber,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
                fontFeatures: [
                  const FontFeature.tabularFigures(),
                ],
              ),
            ),
            // Bottom row: Name and expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARDHOLDER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expiry,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
