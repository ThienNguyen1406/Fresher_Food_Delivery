import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
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
import 'package:fresher_food/roles/user/page/checkout/widgets/stripe_card_input.dart';
import 'package:fresher_food/roles/user/page/checkout/widgets/bank_transfer_qr.dart';
import 'package:fresher_food/services/api/stripe_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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
  GlobalKey<StripeCardInputState>? _stripeCardInputKey;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _secondaryColor = const Color(0xFF059669);
  final Color _accentColor = const Color(0xFF8B5CF6);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _stripeCardInputKey = GlobalKey<StripeCardInputState>();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      final publishableKey = await _stripeApi.getPublishableKey();
      Stripe.publishableKey = publishableKey;
      setState(() {
        _stripeInitialized = true;
      });
    } catch (e) {
      print('Error initializing Stripe: $e');
    }
  }

  void _initializeProvider(CheckoutProvider provider) {
    provider.loadUserInfo();
    provider.loadPaymentMethods();
    provider.loadAvailableCoupons();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CheckoutProvider(
        selectedItems: widget.selectedItems,
        totalAmount: widget.totalAmount,
      ),
      child: Scaffold(
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
        body: Consumer<CheckoutProvider>(
          builder: (context, provider, child) {
            // Khởi tạo provider khi widget được build lần đầu
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!provider.isLoading &&
                  provider.state.name.isEmpty &&
                  provider.state.phone.isEmpty) {
                _initializeProvider(provider);
              }
            });

            if (provider.isLoading || provider.isProcessingPayment) {
              return CheckoutLoadingScreen(
                primaryColor: _primaryColor,
                accentColor: _accentColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
              );
            }
            return _buildCheckoutContent(provider);
          },
        ),
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
            provider: provider,
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
          ),

          // Hiển thị form nhập thẻ khi chọn thẻ tín dụng (chỉ khi Stripe đã khởi tạo)
          if (provider.paymentMethod == 'stripe' &&
              Stripe.publishableKey.isNotEmpty) ...[
            const SizedBox(height: 16),
            StripeCardInput(
              key: _stripeCardInputKey,
              surfaceColor: _surfaceColor,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
            ),
          ],

          // Hiển thị QR code chuyển khoản khi chọn banking/transfer
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

    provider.updateProcessingPayment(true);

    try {
      if (provider.paymentMethod == 'cod') {
        await _processCODPayment(provider);
      } else if (provider.paymentMethod == 'momo') {
        await _processMoMoPayment(provider);
      } else if (provider.paymentMethod == 'stripe') {
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
    } finally {
      provider.updateProcessingPayment(false);
    }
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

      // Tạo payment intent
      final finalAmount = provider.state.finalAmount;
      final paymentIntentData = await _stripeApi.createPaymentIntent(
        amount: finalAmount,
        userId: userId,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String;
      final paymentIntentId = paymentIntentData['paymentIntentId'] as String;

      // Lấy card details từ form
      final cardController = _stripeCardInputKey?.currentState?.cardController;
      if (cardController == null) {
        Navigator.of(context).pop();
        CheckoutSnackbarWidgets.showError(
            context, 'Vui lòng nhập thông tin thẻ');
        return;
      }

      // Xác nhận thanh toán với Stripe
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: provider.state.name,
              phone: provider.state.phone,
              address: Address(
                line1: provider.state.address,
                line2: '',
                city: '',
                state: '',
                country: 'VN',
                postalCode: '',
              ),
            ),
          ),
        ),
      );

      Navigator.of(context).pop(); // Đóng dialog loading

      // Xác nhận thanh toán với backend
      final paymentConfirmed = await _stripeApi.confirmPayment(paymentIntentId);

      if (paymentConfirmed) {
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
              child: const Text('Xác nhận'),
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
