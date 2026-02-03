import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fresher_food/models/SavedCard.dart';
import 'package:fresher_food/services/api/stripe_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/stripe_card_input.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/card_preview.dart';

/// Dialog thêm thẻ mới - 80% màn hình
class AddCardDialog extends StatefulWidget {
  final List<SavedCard> savedCards;
  final Function(SavedCard)? onCardSaved;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;

  const AddCardDialog({
    super.key,
    required this.savedCards,
    this.onCardSaved,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  static Future<SavedCard?> show({
    required BuildContext context,
    required List<SavedCard> savedCards,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
  }) async {
    SavedCard? savedCard;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddCardDialog(
        savedCards: savedCards,
        onCardSaved: (card) {
          savedCard = card;
        },
        primaryColor: primaryColor,
        surfaceColor: surfaceColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      ),
    );
    return savedCard;
  }

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  bool _isCardComplete = false;
  bool _isSaving = false;
  String? _errorMessage;
  final TextEditingController _cardholderController = TextEditingController();
  String? _expiryMonth;
  String? _expiryYear;
  String? _brand;
  String? _last4;

  @override
  void dispose() {
    _cardholderController.dispose();
    super.dispose();
  }

  /// Kiểm tra số thẻ có trùng với thẻ đã lưu không
  bool _isCardDuplicate(String? last4) {
    if (last4 == null || last4.isEmpty) return false;
    return widget.savedCards.any((card) => card.last4 == last4);
  }

  /// Lưu thẻ
  Future<void> _saveCard() async {
    if (!_isCardComplete) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin thẻ';
      });
      return;
    }

    // Kiểm tra số thẻ trùng
    if (_isCardDuplicate(_last4)) {
      setState(() {
        _errorMessage = 'Thẻ này đã được lưu. Vui lòng sử dụng thẻ khác.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Tạo PaymentMethod từ CardFormField
      // Lưu ý: Stripe không cho phép lấy số thẻ đầy đủ từ CardFormField
      // Chúng ta cần tạo PaymentMethod trước, sau đó lấy thông tin từ Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (paymentMethod.id.isEmpty) {
        throw Exception('Không thể tạo PaymentMethod');
      }

      // Lấy thông tin thẻ từ PaymentMethod
      final card = paymentMethod.card;
      if (card.last4 == null || card.last4!.isEmpty) {
        throw Exception('PaymentMethod không có thông tin thẻ hợp lệ');
      }

      final last4 = card.last4!;

      // Kiểm tra lại số thẻ trùng (sau khi có last4 từ Stripe)
      if (_isCardDuplicate(last4)) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Thẻ này đã được lưu. Vui lòng sử dụng thẻ khác.';
        });
        return;
      }

      // Lưu thẻ vào backend
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';

      final savedCard = await StripeApi().saveCard(
        paymentMethodId: paymentMethod.id,
        userId: userId,
        cardholderName: _cardholderController.text.trim().isNotEmpty
            ? _cardholderController.text.trim()
            : userInfo['hoTen'] ?? '',
        isDefault: widget.savedCards.isEmpty, // Đặt làm mặc định nếu là thẻ đầu tiên
      );

      if (savedCard != null) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onCardSaved?.call(savedCard);
        }
      } else {
        throw Exception('Không thể lưu thẻ');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        if (e.toString().contains('duplicate') || 
            e.toString().contains('trùng') ||
            e.toString().contains('already')) {
          _errorMessage = 'Thẻ này đã được lưu. Vui lòng sử dụng thẻ khác.';
        } else if (e.toString().contains('card') || 
                   e.toString().contains('invalid')) {
          _errorMessage = 'Thông tin thẻ không hợp lệ. Vui lòng kiểm tra lại.';
        } else {
          _errorMessage = 'Lỗi khi lưu thẻ: ${e.toString()}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: dialogHeight,
        decoration: BoxDecoration(
          color: widget.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Thêm thẻ mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Preview
                    CardPreview(
                      cardNumber: null,
                      cardholderName: _cardholderController.text.isNotEmpty
                          ? _cardholderController.text
                          : null,
                      expiryMonth: _expiryMonth,
                      expiryYear: _expiryYear,
                      brand: _brand,
                    ),

                    const SizedBox(height: 20),

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
                        hintStyle: TextStyle(
                          color: widget.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      style: TextStyle(color: widget.textPrimary),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 20),

                    // Stripe CardFormField
                    StripeCardInput(
                      surfaceColor: widget.surfaceColor,
                      textPrimary: widget.textPrimary,
                      textSecondary: widget.textSecondary,
                      primaryColor: widget.primaryColor,
                      onCardComplete: (isComplete) {
                        setState(() {
                          _isCardComplete = isComplete;
                        });
                      },
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: widget.textSecondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving || !_isCardComplete ? null : _saveCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: widget.textSecondary.withOpacity(0.3),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Lưu thẻ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

