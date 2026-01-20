import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/roles/user/page/favorite/provider/favorite_service.dart';
import 'package:fresher_food/roles/user/page/favorite/provider/favorite_state.dart';


class FavoriteProvider with ChangeNotifier {
  final FavoriteService _service = FavoriteService();
  FavoriteState _state = FavoriteState(
    favoriteProducts: [],
    isLoading: true,
    isLoggedIn: false,
  );

  // Getters
  FavoriteState get state => _state;
  List<Product> get favoriteProducts => _state.favoriteProducts;
  bool get isLoading => _state.isLoading;
  bool get isLoggedIn => _state.isLoggedIn;
  bool get hasError => _state.error != null;
  String? get error => _state.error;
  bool get isEmpty => _state.favoriteProducts.isEmpty;

  // State management methods
  void _updateState(FavoriteState newState) {
    print('FavoriteProvider: _updateState called');
    print('FavoriteProvider: Old state - products: ${_state.favoriteProducts.length}, isLoading: ${_state.isLoading}');
    print('FavoriteProvider: New state - products: ${newState.favoriteProducts.length}, isLoading: ${newState.isLoading}');
    _state = newState;
    notifyListeners();
    print('FavoriteProvider: notifyListeners() called');
  }

  // Business logic methods
  Future<void> initialize() async {
    try {
      _updateState(_state.loading());
      final isLoggedIn = await _service.checkLoginStatus();
      _updateState(_state.loggedIn(isLoggedIn));

      if (isLoggedIn) {
        await loadFavorites();
      } else {
        _updateState(_state.copyWith(isLoading: false));
      }
    } catch (e) {
      _updateState(_state.errorState('Lỗi khởi tạo: $e'));
    }
  }

  Future<void> loadFavorites() async {
    try {
      print('FavoriteProvider: Starting to load favorites...');
      _updateState(_state.loading());
      final favorites = await _service.loadFavorites();
      print('FavoriteProvider: Loaded ${favorites.length} favorites from service');
      print('FavoriteProvider: Products details: ${favorites.map((p) => p.tenSanPham).toList()}');
      final newState = _state.success(favorites);
      _updateState(newState);
      print('FavoriteProvider: State updated - favoriteProducts.length = ${_state.favoriteProducts.length}');
      print('FavoriteProvider: State updated - isEmpty = ${isEmpty}');
    } catch (e, stackTrace) {
      print('FavoriteProvider: Error loading favorites: $e');
      print('FavoriteProvider: Stack trace: $stackTrace');
      _updateState(_state.errorState('Lỗi tải danh sách yêu thích: $e'));
    }
  }

  Future<void> removeFromFavorites(Product product) async {
    try {
      final success = await _service.removeFromFavorites(product.maSanPham);
      
      if (success) {
        final updatedFavorites = List<Product>.from(_state.favoriteProducts)
          ..removeWhere((p) => p.maSanPham == product.maSanPham);
        _updateState(_state.success(updatedFavorites));
      } else {
        throw Exception('Không thể xóa khỏi danh sách yêu thích');
      }
    } catch (e) {
      _updateState(_state.errorState('Lỗi xóa sản phẩm: $e'));
      rethrow;
    }
  }

  void clearError() {
    _updateState(_state.copyWith(error: null));
  }

  // Helper methods
  String formatPrice(double price) {
    return _service.formatPrice(price);
  }

  bool isProductInFavorites(String productId) {
    return _state.favoriteProducts.any((product) => product.maSanPham == productId);
  }

  void addProductToFavorites(Product product) {
    if (!isProductInFavorites(product.maSanPham)) {
      final updatedFavorites = List<Product>.from(_state.favoriteProducts)..add(product);
      _updateState(_state.success(updatedFavorites));
    }
  }
}