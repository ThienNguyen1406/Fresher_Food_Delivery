import 'package:fresher_food/models/Cart.dart';

class CartState {
  final List<CartItem> cartItems;
  final List<CartItem> selectedItems;
  final double tongTien;
  final double selectedTotal;
  final int tongSoLuong;
  final bool isLoading;
  final bool isLoggedIn;
  final bool selectAll;

  const CartState({
    this.cartItems = const [],
    this.selectedItems = const [],
    this.tongTien = 0,
    this.selectedTotal = 0,
    this.tongSoLuong = 0,
    this.isLoading = true,
    this.isLoggedIn = false,
    this.selectAll = false,
  });

  CartState copyWith({
    List<CartItem>? cartItems,
    List<CartItem>? selectedItems,
    double? tongTien,
    double? selectedTotal,
    int? tongSoLuong,
    bool? isLoading,
    bool? isLoggedIn,
    bool? selectAll,
  }) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      selectedItems: selectedItems ?? this.selectedItems,
      tongTien: tongTien ?? this.tongTien,
      selectedTotal: selectedTotal ?? this.selectedTotal,
      tongSoLuong: tongSoLuong ?? this.tongSoLuong,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      selectAll: selectAll ?? this.selectAll,
    );
  }
}
