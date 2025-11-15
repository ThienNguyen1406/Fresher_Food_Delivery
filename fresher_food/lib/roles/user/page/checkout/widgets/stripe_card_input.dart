import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeCardInput extends StatefulWidget {
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;

  const StripeCardInput({
    super.key,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
  });

  @override
  State<StripeCardInput> createState() => StripeCardInputState();
}

class StripeCardInputState extends State<StripeCardInput> {
  final _cardFormKey = GlobalKey<FormState>();
  CardFormEditController? _cardFormEditController;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    print('🔵 StripeCardInput: Starting initialization...');
    print('🔵 StripeCardInput: PublishableKey isNotEmpty: ${Stripe.publishableKey.isNotEmpty}');
    print('🔵 StripeCardInput: PublishableKey length: ${Stripe.publishableKey.length}');
    
    // Đợi lâu hơn và đảm bảo native SDK đã sẵn sàng
    // Thử gọi applySettings để khởi tạo native SDK
    if (Stripe.publishableKey.isNotEmpty) {
      try {
        print('🔵 StripeCardInput: Calling applySettings to initialize native SDK...');
        await Stripe.instance.applySettings();
        print('🔵 StripeCardInput: ✅ applySettings completed');
      } catch (e) {
        print('⚠️ StripeCardInput: applySettings failed: $e');
      }
    }
    
    // Đợi thêm một chút để đảm bảo native SDK hoàn toàn sẵn sàng
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) {
      print('🔵 StripeCardInput: Widget not mounted, returning');
      return;
    }
    
    // Chỉ khởi tạo controller khi Stripe đã được khởi tạo
    if (Stripe.publishableKey.isNotEmpty) {
      try {
        print('🔵 StripeCardInput: Attempting to create CardFormEditController...');
        _cardFormEditController = CardFormEditController();
        print('🔵 StripeCardInput: ✅ CardFormEditController created successfully');
        
        // Đợi thêm một chút trước khi hiển thị form
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
          print('🔵 StripeCardInput: State updated, _isInitializing = false');
        }
      } catch (e) {
        print('❌ StripeCardInput: Error initializing CardFormEditController: $e');
        print('❌ StripeCardInput: Stack trace: ${StackTrace.current}');
        // Thử lại sau một chút
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted && Stripe.publishableKey.isNotEmpty) {
          try {
            print('🔵 StripeCardInput: Retrying CardFormEditController creation...');
            _cardFormEditController = CardFormEditController();
            print('🔵 StripeCardInput: ✅ CardFormEditController created on retry');
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
          } catch (e2) {
            print('❌ StripeCardInput: Error retrying CardFormEditController: $e2');
            if (mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
          }
        }
      }
    } else {
      print('⚠️ StripeCardInput: PublishableKey is empty, waiting...');
      // Nếu Stripe chưa khởi tạo, thử lại sau một chút
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted && Stripe.publishableKey.isNotEmpty && _cardFormEditController == null) {
        print('🔵 StripeCardInput: Retrying initialization after delay...');
        _initializeController();
      } else if (mounted) {
        print('⚠️ StripeCardInput: Still no publishable key, giving up');
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cardFormEditController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: widget.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin thẻ tín dụng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hiển thị form nhập thẻ - chỉ khi Stripe đã được khởi tạo và controller đã sẵn sàng
            Builder(
              builder: (context) {
                final canShow = _cardFormEditController != null && 
                    !_isInitializing && 
                    Stripe.publishableKey.isNotEmpty;
                
                print('🔵 StripeCardInput build: canShow=$canShow, controller=${_cardFormEditController != null}, isInitializing=$_isInitializing, hasKey=${Stripe.publishableKey.isNotEmpty}');
                
                if (canShow) {
                  return Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: CardFormField(
                      controller: _cardFormEditController!,
                      style: CardFormStyle(
                        borderColor: widget.textSecondary.withOpacity(0.3),
                        borderWidth: 1,
                        borderRadius: 8,
                        textColor: widget.textPrimary,
                        placeholderColor: widget.textSecondary,
                        backgroundColor: widget.surfaceColor,
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: widget.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Stripe.publishableKey.isEmpty
                                ? 'Đang khởi tạo Stripe...'
                                : _isInitializing
                                    ? 'Đang khởi tạo form thanh toán...'
                                    : 'Đang tải form thanh toán...',
                            style: TextStyle(
                              color: widget.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Debug: controller=${_cardFormEditController != null}, init=$_isInitializing, key=${Stripe.publishableKey.isNotEmpty}',
                            style: TextStyle(
                              color: widget.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  CardFormEditController? get cardController => _cardFormEditController;
}

// Extension để truy cập cardController từ bên ngoài
extension StripeCardInputExtension on GlobalKey<StripeCardInputState> {
  CardFormEditController? get cardController => currentState?.cardController;
}
