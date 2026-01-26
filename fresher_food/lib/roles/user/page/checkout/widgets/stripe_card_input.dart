import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/card_preview.dart';

/// Widget đơn giản để hiển thị CardFormField
/// PHẢI là StatefulWidget để không bị recreate
/// KHÔNG dùng controller, provider, opacity, ignorepointer
/// Stripe tự quản lý card state
class StripeCardInput extends StatefulWidget {
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Function(bool)? onCardComplete; // Callback để track card complete status
  final VoidCallback? onCardConfirmed; // Callback khi thẻ được xác nhận
  final VoidCallback? onClose; // Callback khi đóng form

  const StripeCardInput({
    super.key,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    this.onCardComplete,
    this.onCardConfirmed,
    this.onClose,
  });

  @override
  State<StripeCardInput> createState() => _StripeCardInputState();
}

class _StripeCardInputState extends State<StripeCardInput> {
  bool _cardComplete = false;
  final TextEditingController _cardholderController = TextEditingController();
  String? _expiryMonth;
  String? _expiryYear;
  String? _brand;

  @override
  Widget build(BuildContext context) {
    if (Stripe.publishableKey.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.primaryColor),
              const SizedBox(height: 12),
              Text(
                'Đang khởi tạo Stripe...',
                style: TextStyle(
                  color: widget.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header với nút đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhập thông tin thẻ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.textPrimary,
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(
                  Icons.close,
                  color: widget.textSecondary,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card Preview
          CardPreview(
            cardNumber: null, // Không hiển thị số thẻ đầy đủ vì CardFormField không cung cấp
            cardholderName: _cardholderController.text.isNotEmpty ? _cardholderController.text : null,
            expiryMonth: _expiryMonth,
            expiryYear: _expiryYear,
            brand: _brand,
          ),
          const SizedBox(height: 16),
          // Cardholder name input
          TextField(
            controller: _cardholderController,
            decoration: InputDecoration(
              labelText: 'Tên chủ thẻ',
              hintText: 'Nhập tên chủ thẻ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.textSecondary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.primaryColor,
                  width: 2,
                ),
              ),
              labelStyle: TextStyle(color: widget.textSecondary),
              hintStyle: TextStyle(color: widget.textSecondary.withOpacity(0.5)),
            ),
            style: TextStyle(color: widget.textPrimary),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          // Stripe CardFormField
          CardFormField(
            onCardChanged: (details) {
              final isComplete = details?.complete ?? false;
              
              // Cố gắng lấy thông tin từ details (nếu có)
              // Lưu ý: CardFormField không cung cấp số thẻ đầy đủ vì lý do bảo mật
              // Chỉ có thể lấy last4, brand, expMonth, expYear
              if (details != null) {
                setState(() {
                  _cardComplete = isComplete;
                  // Không thể lấy số thẻ đầy đủ từ CardFormField
                  // Chỉ hiển thị placeholder hoặc last4 nếu có
                  _expiryMonth = details.expiryMonth?.toString().padLeft(2, '0');
                  _expiryYear = details.expiryYear?.toString().substring(2);
                  _brand = details.brand;
                });
              } else {
                setState(() {
                  _cardComplete = isComplete;
                });
              }
              
              // Track card complete status in provider (nếu có)
              try {
                final provider = Provider.of<CheckoutProvider>(context, listen: false);
                provider.setStripeCardComplete(isComplete);
              } catch (e) {
                // Không có CheckoutProvider (dùng trong add card page)
                // Dùng callback nếu có
              }
              // Gọi callback nếu có
              widget.onCardComplete?.call(isComplete);
            },
            style: CardFormStyle(
              borderColor: widget.textSecondary.withOpacity(0.3),
              borderWidth: 1,
              borderRadius: 8,
              textColor: widget.textPrimary,
              placeholderColor: widget.textSecondary,
              backgroundColor: widget.surfaceColor,
            ),
          ),
          const SizedBox(height: 16),
          // Chỉ hiển thị buttons nếu có callbacks
          if (widget.onClose != null || widget.onCardConfirmed != null)
            Row(
              children: [
                if (widget.onClose != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.textSecondary,
                        side: BorderSide(
                          color: widget.textSecondary.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onCardConfirmed != null) const SizedBox(width: 12),
                ],
                if (widget.onCardConfirmed != null)
                  Expanded(
                    flex: widget.onClose != null ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: _cardComplete ? _confirmCard : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: widget.textSecondary.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Xác nhận thẻ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            // Nếu không có callbacks, hiển thị button "Lưu thẻ" mặc định
            ElevatedButton(
              onPressed: _cardComplete ? _confirmCard : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: widget.textSecondary.withOpacity(0.3),
              ),
              child: const Text(
                'Lưu thẻ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardholderController.dispose();
    super.dispose();
  }

  void _confirmCard() {
    if (_cardComplete) {
      widget.onCardConfirmed?.call();
    }
  }
}
