// providers/productdetail_provider.dart
import 'package:flutter/foundation.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_service.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_state.dart';


class ProductDetailProvider with ChangeNotifier {
  final ProductDetailService _productDetailService = ProductDetailService();
  ProductDetailState _state =  ProductDetailState();

  // Getters
  ProductDetailState get state => _state;
  Product? get product => _state.product;
  bool get isLoading => _state.isLoading;
  String get errorMessage => _state.errorMessage;
  int get quantity => _state.quantity;
  bool get isFavorite => _state.isFavorite;
  List<Rating> get ratings => _state.ratings;
  RatingStats get ratingStats => _state.ratingStats;
  bool get isLoadingRatings => _state.isLoadingRatings;
  bool get hasUserRated => _state.hasUserRated;
  Rating? get userRating => _state.userRating;

  // Methods
  Future<void> loadProductDetail(String productId) async {
    _updateState(_state.loading());
    
    try {
      final product = await _productDetailService.getProductDetail(productId);
      if (product != null) {
        _updateState(_state.success(product));
        await _loadRatings(productId);
        await _checkFavoriteStatus(productId);
      } else {
        _updateState(_state.error('Không tìm thấy sản phẩm'));
      }
    } catch (e) {
      _updateState(_state.error(e.toString()));
    }
  }

  Future<void> _checkFavoriteStatus(String productId) async {
    try {
      final isFavorite = await _productDetailService.checkFavoriteStatus(productId);
      _updateState(_state.toggleFavorite(isFavorite));
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _loadRatings(String productId) async {
    _updateState(_state.loadingRatings());
    
    try {
      final stats = await _productDetailService.getRatingStats(productId);
      final ratings = await _productDetailService.getRatingsByProduct(productId);
      final userRating = await _productDetailService.getUserRating(productId);
      
      _updateState(_state.ratingsSuccess(
        ratingStats: stats,
        ratings: ratings,
        userRating: userRating,
      ));
    } catch (e) {
      print('Error loading ratings: $e');
      _updateState(_state.ratingsError());
    }
  }

  Future<void> toggleFavorite(String productId) async {
    try {
      final newFavoriteStatus = await _productDetailService.toggleFavorite(
        productId, 
        _state.isFavorite
      );
      _updateState(_state.toggleFavorite(newFavoriteStatus));
    } catch (e) {
      rethrow;
    }
  }

  void increaseQuantity() {
    if (_state.product != null && _state.quantity < _state.product!.soLuongTon) {
      _updateState(_state.updateQuantity(_state.quantity + 1));
    }
  }

  void decreaseQuantity() {
    if (_state.quantity > 1) {
      _updateState(_state.updateQuantity(_state.quantity - 1));
    }
  }

  void setMaxQuantity() {
    if (_state.product != null) {
      _updateState(_state.updateQuantity(_state.product!.soLuongTon));
    }
  }

  Future<bool> addToCart() async {
    if (_state.product == null) return false;
    
    try {
      return await _productDetailService.addToCart(
        _state.product!.maSanPham, 
        _state.quantity
      );
    } catch (e) {
      rethrow;
    }
  }

  // Rating methods
  Future<bool> submitRating(Rating rating) async {
    try {
      final success = await _productDetailService.submitRating(rating);
      if (success) {
        await _loadRatings(rating.maSanPham);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteRating(String productId) async {
    try {
      final success = await _productDetailService.deleteRating(productId);
      if (success) {
        _updateState(_state.removeUserRating());
        await _loadRatings(productId);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      return await _productDetailService.isUserLoggedIn();
    } catch (e) {
      return false;
    }
  }

  // Private method
  void _updateState(ProductDetailState newState) {
    _state = newState;
    notifyListeners();
  }

  // Helper methods
  bool get isOutOfStock => product!.soLuongTon <= 0;
  bool get isLowStock => (product?.soLuongTon ?? 0) < 10 && (product?.soLuongTon ?? 0) > 0;
}