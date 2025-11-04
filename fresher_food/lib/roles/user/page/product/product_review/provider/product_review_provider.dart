import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_review/provider/product_detail_service.dart';
import 'product_review_state.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/models/Product.dart';

class ProductReviewProvider extends ChangeNotifier {
  final String productId;
  final ProductReviewService _service;

  ProductReviewState _state = ProductReviewState.initial();
  ProductReviewState get state => _state;

  final TextEditingController _reviewController = TextEditingController();
  TextEditingController get reviewController => _reviewController;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _starColor = const Color(0xFFFFD700);

  Color get primaryColor => _primaryColor;
  Color get backgroundColor => _backgroundColor;
  Color get surfaceColor => _surfaceColor;
  Color get textPrimary => _textPrimary;
  Color get textSecondary => _textSecondary;
  Color get starColor => _starColor;

  String get productName => _state.product?.tenSanPham ?? 'Sản phẩm';

  ProductReviewProvider({
    required this.productId,
    ProductReviewService? service,
  }) : _service = service ?? ProductReviewService() {
    _loadProductAndReviews();
  }

  Future<void> _loadProductAndReviews() async {
    _updateState(isLoading: true);
    
    try {
      final productFuture = _service.getProduct(productId);
      final reviewsFuture = _service.loadReviews(productId);

      final results = await Future.wait([productFuture, reviewsFuture]);

      final product = results[0] as Product;
      final reviewsData = results[1] as Map<String, dynamic>;

      _updateState(
        product: product,
        reviews: reviewsData['reviews'] as List<Rating>,
        ratingStats: reviewsData['stats'] as RatingStats,
        userReview: reviewsData['userReview'] as Rating?,
      );
      
      if (reviewsData['userReview'] != null) {
        final userReview = reviewsData['userReview'] as Rating;
        _reviewController.text = userReview.noiDung ?? '';
      }
    } catch (e) {
      _handleError('Lỗi tải thông tin sản phẩm: $e');
    } finally {
      _updateState(isLoading: false);
    }
  }

  Future<void> reloadData() async {
    await _loadProductAndReviews();
  }

  Future<void> submitReview() async {
    if (_state.selectedStars == 0) {
      _handleError('Vui lòng chọn số sao');
      return;
    }

    _updateState(isSubmitting: true);

    try {
      final success = await _service.submitReview(
        productId: productId,
        selectedStars: _state.selectedStars,
        reviewText: _reviewController.text,
        existingReview: _state.userReview,
      );

      if (success) {
        _handleSuccess(_state.userReview != null
            ? 'Cập nhật đánh giá thành công!'
            : 'Gửi đánh giá thành công!');
        await reloadData();
        _updateState(isEditMode: false);
      } else {
        throw Exception('Không thể gửi đánh giá');
      }
    } catch (e) {
      _handleError('Lỗi gửi đánh giá: $e');
    } finally {
      _updateState(isSubmitting: false);
    }
  }

  Future<void> deleteReview() async {
    _updateState(isLoading: true);

    try {
      final success = await _service.deleteReview(productId);
      if (success) {
        _handleSuccess('Xóa đánh giá thành công!');
        await reloadData();
      } else {
        throw Exception('Không thể xóa đánh giá');
      }
    } catch (e) {
      _handleError('Lỗi xóa đánh giá: $e');
    } finally {
      _updateState(isLoading: false);
    }
  }

  void startEditing() {
    _updateState(isEditMode: true);
    if (_state.userReview != null) {
      _updateState(selectedStars: _state.userReview!.soSao);
      _reviewController.text = _state.userReview!.noiDung ?? '';
    }
  }

  void cancelEditing() {
    _updateState(isEditMode: false);
    if (_state.userReview != null) {
      _updateState(selectedStars: _state.userReview!.soSao);
      _reviewController.text = _state.userReview!.noiDung ?? '';
    } else {
      _updateState(selectedStars: 0);
      _reviewController.clear();
    }
  }

  void updateSelectedStars(int stars) {
    _updateState(selectedStars: stars);
  }

  void _updateState({
    List<Rating>? reviews,
    RatingStats? ratingStats,
    Rating? userReview,
    Product? product,
    bool? isLoading,
    bool? isSubmitting,
    int? selectedStars,
    bool? isEditMode,
  }) {
    _state = _state.copyWith(
      reviews: reviews,
      ratingStats: ratingStats,
      userReview: userReview,
      product: product,
      isLoading: isLoading,
      isSubmitting: isSubmitting,
      selectedStars: selectedStars,
      isEditMode: isEditMode,
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
    _reviewController.dispose();
    super.dispose();
  }
}