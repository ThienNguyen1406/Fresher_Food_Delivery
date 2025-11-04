import 'package:fresher_food/models/Coupon.dart';

class VoucherState {
  final List<PhieuGiamGia> allCoupons;
  final List<PhieuGiamGia> displayedCoupons;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final String searchQuery;

  const VoucherState({
    required this.allCoupons,
    required this.displayedCoupons,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.searchQuery,
  });

  VoucherState copyWith({
    List<PhieuGiamGia>? allCoupons,
    List<PhieuGiamGia>? displayedCoupons,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    String? searchQuery,
  }) {
    return VoucherState(
      allCoupons: allCoupons ?? this.allCoupons,
      displayedCoupons: displayedCoupons ?? this.displayedCoupons,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  factory VoucherState.initial() {
    return const VoucherState(
      allCoupons: [],
      displayedCoupons: [],
      isLoading: true,
      hasError: false,
      errorMessage: '',
      searchQuery: '',
    );
  }
}