import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/checkout_section_header.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/delivery_info_card.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/note_card.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/coupon_section.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/payment_method_section.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/selected_products_section.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/total_section.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/checkout_loading_screen.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/checkout_success_screen.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/processing_dialog.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/stock_error_dialog.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/checkout_snackbar_widgets.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/bank_transfer_qr.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/stripe_card_input.dart';
import 'package:fresher_food/models/SavedCard.dart';
import 'package:fresher_food/services/api/stripe_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Màn hình thanh toán - xử lý đặt hàng và thanh toán
class CheckoutPage extends StatefulWidget {
  final List<CartItem> selectedItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _noteController = TextEditingController();
  Timer? _successTimer;
  final StripeApi _stripeApi = StripeApi();
  bool _stripeInitialized = false;
  bool _providerInitialized = false;
  List<SavedCard> _savedCards = [];
  SavedCard? _selectedSavedCard;
  bool _showNewCardForm = false;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _secondaryColor = const Color(0xFF059669);
  final Color _accentColor = const Color(0xFF8B5CF6);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  /// Khối khởi tạo: Khởi tạo Stripe payment gateway
  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  /// Khối chức năng: Khởi tạo Stripe với publishable key
  /// KHÔNG dùng setState - Stripe không cần rebuild UI
  Future<void> _initializeStripe() async {
    try {
      final publishableKey = await _stripeApi.getPublishableKey();
      Stripe.publishableKey = publishableKey;
      _stripeInitialized = true; // Không setState, chỉ cập nhật biến
    } catch (e) {
      print('Error initializing Stripe: $e');
    }
  }

  /// Khối chức năng: Khởi tạo provider - load thông tin người dùng, phương thức thanh toán, mã giảm giá
  void _initializeProvider(CheckoutProvider provider) {
    provider.loadUserInfo();
    provider.loadPaymentMethods();
    provider.loadAvailableCoupons();
    _loadSavedCards(); // Load thẻ đã lưu
  }

  /// Load danh sách thẻ đã lưu
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
        // Tự động chọn thẻ mặc định nếu có
        if (_savedCards.isNotEmpty && _selectedSavedCard == null) {
          _selectedSavedCard = _savedCards.firstWhere(
            (card) => card.isDefault,
            orElse: () => _savedCards.first,
          );
          _showNewCardForm = false;
        }
      });
    } catch (e) {
      print('Error loading saved cards: $e');
    }
  }



  /// Khối chức năng: Tạo mã đơn hàng tạm thời cho VietQR
  String _generateTempOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'DH-${timestamp.toString().substring(timestamp.toString().length - 8)}';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  /// Khối giao diện chính: Hiển thị form thanh toán với các section
  /// Provider đã được tạo ở route, không tạo lại trong build()
  @override
  Widget build(BuildContext context) {
    // Lấy provider từ context (đã được tạo ở route)
    final provider = Provider.of<CheckoutProvider>(context);
    
    // Khởi tạo provider một lần duy nhất
    if (!_providerInitialized) {
      _providerInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProvider(provider);
      });
    }
    
    return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(
            'Thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              fontSize: 18,
            ),
          ),
          backgroundColor: _surfaceColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _textPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: Builder(
          builder: (context) {
            final provider = Provider.of<CheckoutProvider>(context);
            
            // Khởi tạo provider khi widget được build lần đầu
            if (!_providerInitialized) {
              _providerInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeProvider(provider);
              });
            }

            if (provider.isLoading) {
              return CheckoutLoadingScreen(
                primaryColor: _primaryColor,
                accentColor: _accentColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
              );
            }
            
            // Tách CardFormField ra khỏi Consumer để không bị rebuild
            // Chỉ dùng Consumer cho các phần cần rebuild
            return Column(
              children: [
                Expanded(
                  child: Consumer<CheckoutProvider>(
                    builder: (context, provider, child) {
                      return _buildCheckoutContent(provider);
                    },
                  ),
                ),
                // Hiển thị thông báo xác nhận nếu thẻ đã được xác nhận
                // Form thêm thẻ được hiển thị trong BottomSheet (80% màn hình)
                Selector<CheckoutProvider, String>(
                  selector: (_, provider) => provider.paymentMethod,
                  shouldRebuild: (prev, next) => prev != next,
                  builder: (context, paymentMethod, child) {
                    // ✅ Flow đơn giản: Không cần hiển thị thông báo xác nhận thẻ
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        ),
    );
  }

  Widget _buildCheckoutContent(CheckoutProvider provider) {
    _noteController.text = provider.state.note;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutSectionHeader(
            title: 'Thông tin giao hàng',
            icon: Icons.local_shipping_outlined,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
          ),
          DeliveryInfoCard(
            provider: provider,
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
          ),

          const SizedBox(height: 28),

          CheckoutSectionHeader(
            title: 'Ghi chú đơn hàng',
            icon: Icons.note_add_outlined,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
          ),
          NoteCard(
            provider: provider,
            noteController: _noteController,
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            primaryColor: _primaryColor,
            backgroundColor: _backgroundColor,
          ),

          const SizedBox(height: 28),

          CheckoutSectionHeader(
            title: 'Mã giảm giá',
            icon: Icons.discount_outlined,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
          ),
          CouponSection(
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            primaryColor: _primaryColor,
            backgroundColor: _backgroundColor,
          ),

          const SizedBox(height: 28),

          CheckoutSectionHeader(
            title: 'Phương thức thanh toán',
            icon: Icons.payment_outlined,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
          ),
          PaymentMethodSection(
            provider: provider,
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            primaryColor: _primaryColor,
            accentColor: _accentColor,
            backgroundColor: _backgroundColor,
            savedCards: _savedCards,
            selectedCard: _showNewCardForm ? null : _selectedSavedCard,
            onCardSelected: (card) {
              setState(() {
                _selectedSavedCard = card;
                _showNewCardForm = false;
              });
            },
            onCardSaved: () async {
              // Reload danh sách thẻ sau khi lưu thành công
              await _loadSavedCards();
            },
            onAddNewCard: () async {
              // Dialog sẽ được mở từ payment_method_section
              // Không cần set _showNewCardForm nữa vì dialog sẽ xử lý
            },
          ),

          // ✅ Hiển thị CardFormField khi chọn Stripe và chọn "Thêm thẻ mới"
          if (provider.paymentMethod == 'stripe' && _showNewCardForm) ...[
            const SizedBox(height: 16),
            StripeCardInput(
              surfaceColor: _surfaceColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              onCardComplete: (isComplete) {
                // Cập nhật trạng thái thẻ trong provider (không rebuild UI)
                provider.setStripeCardComplete(isComplete);
              },
            ),
          ],

          // Hiển thị QR code chuyển khoản CHỈ KHI chọn banking/transfer
          // KHÔNG hiển thị khi chọn COD (thanh toán khi nhận hàng)
          if (provider.paymentMethod == 'banking' ||
              provider.paymentMethod == 'transfer') ...[
            const SizedBox(height: 16),
            BankTransferQR(
              surfaceColor: _surfaceColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              backgroundColor: _backgroundColor,
              onConfirmPayment: () => _processBankTransfer(provider),
              maDonHang: _generateTempOrderId(), // Mã đơn hàng tạm thời
              soTien: provider.finalAmount,
            ),
          ],

          const SizedBox(height: 28),

          CheckoutSectionHeader(
            title: 'Sản phẩm đã chọn',
            icon: Icons.shopping_bag_outlined,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
          ),
          SelectedProductsSection(
            provider: provider,
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            primaryColor: _primaryColor,
            backgroundColor: _backgroundColor,
          ),

          const SizedBox(height: 28),

          TotalSection(
            provider: provider,
            onPlaceOrder: () => _placeOrder(provider),
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            primaryColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CheckoutProvider provider) async {
    if (!provider.validateForm()) {
      CheckoutSnackbarWidgets.showError(
          context, 'Vui lòng điền đầy đủ thông tin giao hàng');
      return;
    }

    final outOfStockItem = provider.getOutOfStockItem();
    if (outOfStockItem != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StockErrorDialog(
            item: outOfStockItem,
            surfaceColor: _surfaceColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
          );
        },
      );
      return;
    }

    // ❌ KHÔNG gọi notifyListeners() trước confirmPayment
    // Vì nó sẽ rebuild CardFormField → mất dữ liệu thẻ
    // Chỉ dùng dialog để hiển thị loading  

    try {
      if (provider.paymentMethod == 'cod') {
        await _processCODPayment(provider);
      } else if (provider.paymentMethod == 'momo') {
        await _processMoMoPayment(provider);
      } else if (provider.paymentMethod == 'stripe') {
        // Kiểm tra thẻ đã complete chưa (chỉ khi dùng thẻ mới)
        if (_showNewCardForm && !provider.stripeCardComplete) {
          CheckoutSnackbarWidgets.showError(
            context,
            'Vui lòng nhập đầy đủ thông tin thẻ (số thẻ, ngày hết hạn, CVV)',
          );
          return;
        }
        await _processStripePayment(provider);
      } else if (provider.paymentMethod == 'banking' ||
          provider.paymentMethod == 'transfer') {
        // Banking/Transfer được xử lý qua nút trong BankTransferQR widget
        CheckoutSnackbarWidgets.showError(
            context, 'Vui lòng quét QR code và nhấn "Xác nhận đã thanh toán"');
      } else {
        CheckoutSnackbarWidgets.showError(
            context, 'Phương thức thanh toán không được hỗ trợ');
      }
    } catch (e) {
      CheckoutSnackbarWidgets.showError(
          context, 'Lỗi trong quá trình thanh toán: $e');
    }
    // ❌ KHÔNG gọi updateProcessingPayment(false) vì không dùng isProcessingPayment để điều khiển UI
    // Dialog đã tự đóng, không cần notifyListeners()
  }

  Future<void> _processCODPayment(CheckoutProvider provider) async {
    try {
      // Tạo đơn hàng ngay lập tức, không hiển thị dialog loading
      final success = await provider.createOrder('cod');

      if (success) {
        // Chuyển thẳng sang màn hình thành công
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CheckoutSuccessScreen(
              primaryColor: _primaryColor,
              secondaryColor: _secondaryColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              backgroundColor: _backgroundColor,
            ),
          ),
        );
      } else {
        CheckoutSnackbarWidgets.showError(context, 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      CheckoutSnackbarWidgets.showError(
          context, 'Lỗi khi xử lý thanh toán COD: $e');
    }
  }

  Future<void> _processMoMoPayment(CheckoutProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProcessingDialog(
          message: 'Đang chuyển hướng đến MoMo...',
          primaryColor: _primaryColor,
          accentColor: _accentColor,
          textPrimary: _textPrimary,
          surfaceColor: _surfaceColor,
        );
      },
    );
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();

    try {
      final success = await provider.createOrder('momo');
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CheckoutSuccessScreen(
              primaryColor: _primaryColor,
              secondaryColor: _secondaryColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              backgroundColor: _backgroundColor,
            ),
          ),
        );
      } else {
        CheckoutSnackbarWidgets.showError(
            context, 'Không thể tạo đơn hàng sau thanh toán MoMo');
      }
    } catch (e) {
      CheckoutSnackbarWidgets.showError(
          context, 'Lỗi khi xử lý thanh toán MoMo: $e');
    }
  }

  Future<void> _processStripePayment(CheckoutProvider provider) async {
    if (!_stripeInitialized) {
      CheckoutSnackbarWidgets.showError(context, 'Stripe chưa được khởi tạo');
      return;
    }
    
    // KHÔNG cần controller - Stripe tự quản lý CardFormField

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProcessingDialog(
          message: 'Đang xử lý thanh toán...',
          primaryColor: _primaryColor,
          accentColor: _accentColor,
          textPrimary: _textPrimary,
          surfaceColor: _surfaceColor,
        );
      },
    );

    try {
      // Lấy thông tin user
      final userInfo = await UserApi().getUserInfo();
      final userId = userInfo['maTaiKhoan'] ?? '';

      // ✅ Flow chuẩn: Hỗ trợ cả thẻ mới và thẻ đã lưu
      final finalAmount = provider.state.finalAmount;
      
      // Nếu có thẻ đã lưu được chọn, dùng lại PaymentMethod
      final selectedPaymentMethodId = (_selectedSavedCard != null && !_showNewCardForm) 
          ? _selectedSavedCard!.paymentMethodId 
          : null;
      
      final paymentIntentData = await _stripeApi.createPaymentIntent(
        amount: finalAmount,
        userId: userId,
        paymentMethodId: selectedPaymentMethodId, // null nếu thẻ mới, có ID nếu thẻ đã lưu
      );

      String clientSecret = paymentIntentData['clientSecret'] as String;
      String paymentIntentId = paymentIntentData['paymentIntentId'] as String;

      // Với CardFormField, cần kiểm tra xem form đã có dữ liệu chưa
      // Nhưng thực tế, PaymentMethodParams.card() không tự động lấy dữ liệu từ CardFormField
      // Cần tạo payment method từ CardFormField trước, sau đó confirm payment
      print('🔄 Đang xử lý thanh toán Stripe...');
      print('📝 PaymentMethod: ${provider.paymentMethod}');
      print('📝 ClientSecret: ${clientSecret.substring(0, 20)}...');
      
      try {
        // ✅ Flow chuẩn: Dùng thẻ đã lưu hoặc tạo PaymentMethod mới
        if (_selectedSavedCard != null && !_showNewCardForm) {
          // Sử dụng thẻ đã lưu
          print('💳 Sử dụng thẻ đã lưu: ${_selectedSavedCard!.displayName}');
          print('💳 PaymentMethod ID: ${_selectedSavedCard!.paymentMethodId}');
          
          // Thử update PaymentIntent với PaymentMethod ID
          // Nếu thất bại (do PaymentIntent không có Customer), tạo PaymentIntent mới
          String finalClientSecret = clientSecret;
          String finalPaymentIntentId = paymentIntentId;
          
          try {
            final updateResult = await _stripeApi.updatePaymentIntent(
              paymentIntentId: paymentIntentId,
              paymentMethodId: _selectedSavedCard!.paymentMethodId,
            );
            
            if (updateResult['success'] as bool? ?? false) {
              // Update thành công
              finalClientSecret = updateResult['clientSecret'] as String? ?? clientSecret;
              print('✅ PaymentIntent đã được cập nhật với PaymentMethod');
            } else {
              throw Exception('Update failed');
            }
          } catch (e) {
            // Nếu update thất bại (thường do PaymentIntent không có Customer),
            // tạo PaymentIntent mới với Customer và PaymentMethod
            print('⚠️ Không thể update PaymentIntent, tạo PaymentIntent mới: $e');
            print('🔄 Tạo PaymentIntent mới với Customer và PaymentMethod...');
            
            final newPaymentIntentData = await _stripeApi.createPaymentIntent(
              amount: finalAmount,
              userId: userId,
              paymentMethodId: _selectedSavedCard!.paymentMethodId, // Set PaymentMethodId ngay từ đầu
            );
            
            finalClientSecret = newPaymentIntentData['clientSecret'] as String;
            finalPaymentIntentId = newPaymentIntentData['paymentIntentId'] as String;
            
            print('✅ Đã tạo PaymentIntent mới với Customer và PaymentMethod');
            print('🔍 New PaymentIntent ID: $finalPaymentIntentId');
            print('🔍 New ClientSecret: ${finalClientSecret.substring(0, 30)}...');
          }
          
          // Confirm payment với clientSecret
          // PaymentIntent đã có PaymentMethod và Customer, chỉ cần confirm
          print('🔍 Confirming payment with clientSecret: ${finalClientSecret.substring(0, 30)}...');
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: finalClientSecret,
          );
          
          // Cập nhật paymentIntentId và clientSecret để dùng cho confirm payment sau này (nếu đã tạo mới)
          if (finalPaymentIntentId != paymentIntentId) {
            paymentIntentId = finalPaymentIntentId;
            clientSecret = finalClientSecret;
          }
        } else {
          // Tạo PaymentMethod mới từ CardFormField
          print('💳 Tạo PaymentMethod mới từ CardFormField');
          print('💡 Stripe sẽ tự động lấy card details từ CardFormField');
          print('⚠️ Đảm bảo form đã được nhập đầy đủ (số thẻ, ngày hết hạn, CVV)');
          
          // Confirm payment với PaymentMethodParams.card() (empty)
          // Stripe tự động lấy card details từ CardFormField và tạo PaymentMethod mới
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: clientSecret,
            data: const PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(),
            ),
          );
        }
        
        print('✅ Payment confirmed successfully');
      } catch (e) {
        print('❌ Error confirming payment: $e');
        Navigator.of(context).pop();
        String errorMessage;
        if (e.toString().contains('Card details not complete') || 
            e.toString().contains('details not complete')) {
          errorMessage = 'Vui lòng nhập đầy đủ thông tin thẻ:\n- Số thẻ\n- Ngày hết hạn (MM/YY)\n- CVV (3-4 chữ số)';
        } else if (e.toString().contains('card') || 
            e.toString().contains('invalid') || 
            e.toString().contains('number') ||
            e.toString().contains('expiry') ||
            e.toString().contains('cvc')) {
          errorMessage = 'Thông tin thẻ không hợp lệ. Vui lòng kiểm tra lại:\n- Số thẻ (16 chữ số)\n- Ngày hết hạn (MM/YY)\n- CVV (3-4 chữ số)';
        } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
          errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra lại kết nối mạng và thử lại.';
        } else if (e.toString().contains('Form thanh toán chưa sẵn sàng')) {
          errorMessage = 'Form thanh toán chưa sẵn sàng. Vui lòng đợi một chút và thử lại.';
        } else {
          errorMessage = 'Lỗi khi xử lý thanh toán. Vui lòng thử lại.';
        }
        CheckoutSnackbarWidgets.showError(context, errorMessage);
        return;
      }

      Navigator.of(context).pop(); // Đóng dialog loading

      // ✅ Xác nhận thanh toán với backend - Backend sẽ attach PaymentMethod vào Customer
      // userInfo và userId đã được khai báo ở trên (dòng 513-514)
      final paymentResult = await _stripeApi.confirmPayment(
        paymentIntentId: paymentIntentId,
        userId: userId,
      );
      final paymentConfirmed = paymentResult['success'] as bool? ?? false;
      final paymentMethodId = paymentResult['paymentMethodId'] as String?;

      if (paymentConfirmed && paymentMethodId != null) {
        // ✅ Lưu thẻ sau khi thanh toán thành công (chỉ lần đầu, nếu chưa có trong DB)
        // Backend đã attach PaymentMethod vào Customer, giờ lưu vào database
        if (_showNewCardForm || _selectedSavedCard == null) {
          try {
            await _stripeApi.saveCard(
              paymentMethodId: paymentMethodId,
              userId: userId,
              cardholderName: userInfo['hoTen'] ?? '',
              isDefault: false, // Không đặt làm mặc định khi lưu từ thanh toán
            );
            print('✅ PaymentMethod saved successfully: $paymentMethodId');
            // Reload danh sách thẻ
            await _loadSavedCards();
          } catch (e) {
            // Không throw error nếu lưu thẻ thất bại (có thể đã tồn tại)
            print('⚠️ Could not save PaymentMethod: $e');
          }
        }
        
        print('✅ Payment confirmed successfully');

        // Tạo đơn hàng
        final success = await provider.createOrder('stripe');
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CheckoutSuccessScreen(
                primaryColor: _primaryColor,
                secondaryColor: _secondaryColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                backgroundColor: _backgroundColor,
              ),
            ),
          );
        } else {
          CheckoutSnackbarWidgets.showError(
              context, 'Không thể tạo đơn hàng sau thanh toán');
        }
      } else {
        CheckoutSnackbarWidgets.showError(
            context, 'Thanh toán không thành công');
      }
    } catch (e) {
      Navigator.of(context).pop();
      CheckoutSnackbarWidgets.showError(
          context, 'Lỗi khi xử lý thanh toán thẻ: $e');
    }
  }

  Future<void> _processBankTransfer(CheckoutProvider provider) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Xác nhận thanh toán',
            style: TextStyle(color: _textPrimary),
          ),
          content: Text(
            'Bạn đã chuyển khoản thành công?',
            style: TextStyle(color: _textSecondary),
          ),
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Hủy',
                style: TextStyle(color: _textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProcessingDialog(
            message: 'Đang xử lý đơn hàng...',
            primaryColor: _primaryColor,
            accentColor: _accentColor,
            textPrimary: _textPrimary,
            surfaceColor: _surfaceColor,
          );
        },
      );

      try {
        // Tạo đơn hàng với trạng thái pending (chờ xác nhận thanh toán)
        final success = await provider.createOrder('banking');
        Navigator.of(context).pop(); // Đóng dialog loading

        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CheckoutSuccessScreen(
                primaryColor: _primaryColor,
                secondaryColor: _secondaryColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                backgroundColor: _backgroundColor,
              ),
            ),
          );
        } else {
          CheckoutSnackbarWidgets.showError(context, 'Không thể tạo đơn hàng');
        }
      } catch (e) {
        Navigator.of(context).pop();
        CheckoutSnackbarWidgets.showError(
            context, 'Lỗi khi xử lý đơn hàng: $e');
      }
    }
  }
}
