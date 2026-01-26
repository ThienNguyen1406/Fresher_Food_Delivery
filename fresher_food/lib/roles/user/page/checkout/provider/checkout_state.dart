import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/models/Pay.dart';

class CheckoutState {
  final List<CartItem> selectedItems;
  final double totalAmount;

  // Form data
  String name;
  String phone;
  String address;
  String note;

  // Payment & Coupon
  String paymentMethod;
  String selectedPaymentId;
  List<Pay> paymentMethods;
  List<PhieuGiamGia> availableCoupons;
  PhieuGiamGia? selectedCoupon;

  // UI state
  bool isLoading;
  bool isProcessingPayment;
  bool stripeCardComplete; // Track if Stripe card form is complete

  // Calculations
  double discountAmount;
  double finalAmount;
  double shippingFee;

  CheckoutState({
    required this.selectedItems,
    required this.totalAmount,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.note = '',
    this.paymentMethod = 'cod',
    this.selectedPaymentId = '',
    this.paymentMethods = const [],
    this.availableCoupons = const [],
    this.selectedCoupon,
    this.isLoading = false,
    this.isProcessingPayment = false,
    this.discountAmount = 0.0,
    this.finalAmount = 0.0,
    this.shippingFee = 25000,
    this.stripeCardComplete = false,
  });

  CheckoutState copyWith({
    List<CartItem>? selectedItems,
    double? totalAmount,
    String? name,
    String? phone,
    String? address,
    String? note,
    String? paymentMethod,
    String? selectedPaymentId,
    List<Pay>? paymentMethods,
    List<PhieuGiamGia>? availableCoupons,
    PhieuGiamGia? selectedCoupon,
    bool? clearCoupon = false, // Flag để clear coupon
    bool? isLoading,
    bool? isProcessingPayment,
    double? discountAmount,
    double? finalAmount,
    double? shippingFee,
    bool? stripeCardComplete,
  }) {
    return CheckoutState(
      selectedItems: selectedItems ?? this.selectedItems,
      totalAmount: totalAmount ?? this.totalAmount,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedPaymentId: selectedPaymentId ?? this.selectedPaymentId,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      availableCoupons: availableCoupons ?? this.availableCoupons,
      selectedCoupon: clearCoupon == true ? null : (selectedCoupon ?? this.selectedCoupon),
      isLoading: isLoading ?? this.isLoading,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      stripeCardComplete: stripeCardComplete ?? this.stripeCardComplete,
    );
  }
}
