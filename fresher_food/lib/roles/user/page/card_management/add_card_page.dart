import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fresher_food/services/api/stripe_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/stripe_card_input.dart';
import 'package:fresher_food/models/SavedCard.dart';

class AddCardPage extends StatefulWidget {
  final VoidCallback onCardAdded;

  const AddCardPage({
    super.key,
    required this.onCardAdded,
  });

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final StripeApi _stripeApi = StripeApi();
  bool _cardComplete = false;
  bool _isSaving = false;
  List<SavedCard> _savedCards = [];

  final Color _primaryColor = const Color(0xFF10B981);
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _initializeStripe();
    _loadSavedCards();
  }

  Future<void> _initializeStripe() async {
    try {
      final publishableKey = await _stripeApi.getPublishableKey();
      Stripe.publishableKey = publishableKey;
    } catch (e) {
      print('Error initializing Stripe: $e');
    }
  }

  /// Load danh sách thẻ đã lưu để kiểm tra trùng lặp
  Future<void> _loadSavedCards() async {
    try {
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';
      if (userId.isEmpty) {
        return;
      }
      
      final cards = await _stripeApi.getSavedCards(userId);
      setState(() {
        _savedCards = cards;
      });
    } catch (e) {
      print('Error loading saved cards: $e');
    }
  }

  Future<void> _saveCard() async {
    if (!_cardComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin thẻ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSaving) {
      return; // Đang lưu, không cho phép lưu lại
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Tạo payment method từ card form
      // Stripe sẽ tự động lấy card details từ CardFormField
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (paymentMethod.id.isEmpty) {
        throw Exception('Không thể tạo payment method');
      }

      // Lấy thông tin thẻ từ PaymentMethod
      final cardInfo = paymentMethod.card;
      if (cardInfo == null) {
        setState(() {
          _isSaving = false;
        });
        throw Exception('Không thể lấy thông tin thẻ');
      }

      final newCardLast4 = cardInfo.last4;
      final newCardBrand = cardInfo.brand;
      final newCardExpMonth = cardInfo.expMonth;
      final newCardExpYear = cardInfo.expYear;
      
      if (newCardLast4 == null || newCardLast4.isEmpty) {
        setState(() {
          _isSaving = false;
        });
        throw Exception('Không thể lấy số thẻ từ PaymentMethod');
      }

      // Reload danh sách thẻ để đảm bảo có danh sách mới nhất trước khi kiểm tra
      await _loadSavedCards();

      // So sánh với các thẻ đã lưu
      bool isDuplicate = false;
      final newCardBrandLower = newCardBrand?.toLowerCase() ?? 'card';
      for (final savedCard in _savedCards) {
        final savedCardBrandLower = savedCard.brand.toLowerCase();
        if (savedCard.last4 == newCardLast4 &&
            savedCardBrandLower == newCardBrandLower &&
            savedCard.expMonth == newCardExpMonth &&
            savedCard.expYear == newCardExpYear) {
          isDuplicate = true;
          break;
        }
      }

      if (isDuplicate) {
        // Thẻ đã tồn tại - thông báo và không lưu
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thẻ này đã được lưu trong danh sách thẻ của bạn'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Lấy thông tin user
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';
      
      if (userId.isEmpty) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Lưu thẻ mới
      await _stripeApi.saveCard(
        paymentMethodId: paymentMethod.id,
        userId: userId,
        cardholderName: userInfo['hoTen'] ?? '',
        isDefault: false, // Không đặt làm mặc định khi thêm từ quản lý thẻ
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm thẻ thành công'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCardAdded();
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm thẻ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Thêm thẻ mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vui lòng nhập đầy đủ thông tin thẻ (số thẻ, ngày hết hạn, CVV)',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StripeCardInput(
              surfaceColor: _surfaceColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              onCardComplete: (isComplete) {
                setState(() {
                  _cardComplete = isComplete;
                });
              },
            ),
            const SizedBox(height: 24),
            // Nút Lưu và Hủy
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: BorderSide(
                        color: _textSecondary.withOpacity(0.3),
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
                    onPressed: (_isSaving || !_cardComplete) ? null : _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: _textSecondary.withOpacity(0.3),
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
          ],
        ),
      ),
    );
  }
}
