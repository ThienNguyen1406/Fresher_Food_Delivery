import 'package:flutter/material.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_service.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_state.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  CartState _state = const CartState();
  CartState get state => _state;

  // Initialize
  Future<void> initialize() async {
    await checkLoginStatus();
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _cartService.isLoggedIn();
    _state = _state.copyWith(isLoggedIn: isLoggedIn);
    notifyListeners();

    if (isLoggedIn) {
      await loadCart();
    } else {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Load cart
  Future<void> loadCart() async {
    try {
      final cartResponse = await _cartService.getCart();
      
      // Debug: Log để kiểm tra giá
      for (var item in cartResponse.sanPham) {
        print('[Cart] ${item.tenSanPham}: GiaBan=${item.giaBan}, SoLuong=${item.soLuong}, ThanhTien=${item.thanhTien}');
      }
      
      _state = _state.copyWith(
        cartItems: cartResponse.sanPham,
        tongTien: cartResponse.tongTien,
        tongSoLuong: cartResponse.tongSoLuong,
        isLoading: false,
      );
      _updateSelectedItems();
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Update selected items
  void _updateSelectedItems() {
    final selectedItems =
        _state.cartItems.where((item) => item.isSelected).toList();
    final selectedTotal =
        selectedItems.fold(0.0, (double total, item) => total + item.thanhTien);
    final selectAll = _state.cartItems.isNotEmpty &&
        _state.cartItems.every((item) => item.isSelected);

    _state = _state.copyWith(
      selectedItems: selectedItems,
      selectedTotal: selectedTotal,
      selectAll: selectAll,
    );
  }

  // Toggle select all
  void toggleSelectAll(bool? value) {
    if (value == null) return;

    final updatedCartItems = _state.cartItems.map((item) {
      return item.copyWith(isSelected: value);
    }).toList();

    _state = _state.copyWith(
      cartItems: updatedCartItems,
      selectAll: value,
    );
    _updateSelectedItems();
    notifyListeners();
  }

  // Toggle item selection
  void toggleItemSelection(String productId, bool? value) {
    if (value == null) return;

    final updatedCartItems = _state.cartItems.map((item) {
      if (item.maSanPham == productId) {
        return item.copyWith(isSelected: value);
      }
      return item;
    }).toList();

    _state = _state.copyWith(cartItems: updatedCartItems);
    _updateSelectedItems();
    notifyListeners();
  }

  // Remove from cart
  Future<bool> removeFromCart(String productId, String productName) async {
    try {
      final success = await _cartService.removeFromCart(productId);
      if (success) {
        final updatedCartItems = _state.cartItems
            .where((item) => item.maSanPham != productId)
            .toList();
        final tongTien =
            updatedCartItems.fold(0.0, (total, item) => total + item.thanhTien);
        final tongSoLuong =
            updatedCartItems.fold(0, (total, item) => total + item.soLuong);

        _state = _state.copyWith(
          cartItems: updatedCartItems,
          tongTien: tongTien,
          tongSoLuong: tongSoLuong,
        );
        _updateSelectedItems();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Update quantity
  Future<bool> updateQuantity(CartItem cartItem, int newQuantity) async {
    try {
      final success =
          await _cartService.updateCartItem(cartItem.maSanPham, newQuantity);
      if (success) {
        // Reload cart để lấy giá thực tế từ backend (có Sale và giảm giá hết hạn)
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating quantity: $e');
      return false;
    }
  }

  // Check stock before checkout
  bool checkStockBeforeCheckout() {
    for (var item in _state.selectedItems) {
      if (item.soLuong > item.soLuongTon) {
        return false;
      }
    }
    return true;
  }

  // Get problematic items (out of stock or low stock)
  List<CartItem> getProblematicItems() {
    return _state.selectedItems
        .where((item) => item.soLuong > item.soLuongTon)
        .toList();
  }

  // Refresh cart
  Future<void> refresh() async {
    if (_state.isLoggedIn) {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();
      await loadCart();
    }
  }

  // Clear cart (after successful checkout)
  void clearCart() {
    _state = const CartState(
      isLoading: false,
      isLoggedIn: true,
    );
    notifyListeners();
  }
}
