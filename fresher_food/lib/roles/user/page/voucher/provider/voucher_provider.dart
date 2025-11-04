import 'package:flutter/material.dart';
import 'voucher_state.dart';
import 'voucher_service.dart';
import 'package:fresher_food/models/Coupon.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _service;
  final TextEditingController searchController = TextEditingController();

  VoucherState _state = VoucherState.initial();
  VoucherState get state => _state;

  VoucherProvider({VoucherService? service})
      : _service = service ?? VoucherService() {
    searchController.addListener(_onSearchChanged);
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    _updateState(isLoading: true, hasError: false, errorMessage: '');

    try {
      final coupons = await _service.getAllCoupons();
      _updateState(
        allCoupons: coupons,
        displayedCoupons: coupons,
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _updateState(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
        allCoupons: [],
        displayedCoupons: [],
      );
      _handleError('Lỗi tải mã giảm giá: $errorMessage');
    }
  }

  Future<void> searchCoupons(String query) async {
    if (query.isEmpty) {
      await loadCoupons();
      return;
    }

    _updateState(isLoading: true, hasError: false, errorMessage: '');

    try {
      final searchResults = await _service.searchCoupons(query);
      _updateState(
        displayedCoupons: searchResults,
        isLoading: false,
        searchQuery: query,
      );
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _updateState(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
      );
      _handleError('Lỗi tìm kiếm: $errorMessage');
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    _updateState(searchQuery: query);
    _filterCoupons();
  }

  void _filterCoupons() {
    if (state.searchQuery.isEmpty) {
      _updateState(displayedCoupons: state.allCoupons);
      return;
    }

    final filtered = state.allCoupons.where((coupon) {
      final codeMatch = coupon.code.toLowerCase().contains(state.searchQuery.toLowerCase());
      final descriptionMatch = coupon.moTa.toLowerCase().contains(state.searchQuery.toLowerCase());
      return codeMatch || descriptionMatch;
    }).toList();

    _updateState(displayedCoupons: filtered);
  }

  void clearSearch() {
    searchController.clear();
    loadCoupons();
  }

  void copyVoucherCode(String code) {
    _handleSuccess('Đã sao chép mã: $code');
  }

  Color getVoucherColor(double giaTri) {
    if (giaTri >= 100000) {
      return const Color(0xFFFF6B6B);
    } else if (giaTri >= 50000) {
      return const Color(0xFFFFA726);
    } else if (giaTri >= 20000) {
      return const Color(0xFF667EEA);
    } else {
      return const Color(0xFF00C896);
    }
  }

  String getDiscountText(PhieuGiamGia voucher) {
    if (voucher.giaTri <= 100) {
      return '${voucher.giaTri}%';
    } else {
      return formatPrice(voucher.giaTri.toInt());
    }
  }

  String formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)}Tr';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  void _updateState({
    List<PhieuGiamGia>? allCoupons,
    List<PhieuGiamGia>? displayedCoupons,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    String? searchQuery,
  }) {
    _state = _state.copyWith(
      allCoupons: allCoupons,
      displayedCoupons: displayedCoupons,
      isLoading: isLoading,
      hasError: hasError,
      errorMessage: errorMessage,
      searchQuery: searchQuery,
    );
    notifyListeners();
  }

  void Function(String message)? onError;
  void Function(String message)? onSuccess;

  void _handleError(String message) {
    onError?.call(message);
  }

  void _handleSuccess(String message) {
    onSuccess?.call(message);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}