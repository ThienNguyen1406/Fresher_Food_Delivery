import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api/rating_api.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api/product_api.dart';

class ProductReviewService {
  final RatingApi _ratingApi;
  final UserApi _userApi;
  final ProductApi _productApi;

  ProductReviewService({
    RatingApi? ratingApi,
    UserApi? userApi,
    ProductApi? productApi,
  })  : _ratingApi = ratingApi ?? RatingApi(),
        _userApi = userApi ?? UserApi(),
        _productApi = productApi ?? ProductApi();

  Future<Product?> getProduct(String productId) async {
    try {
      return await _productApi.getProductById(productId);
    } catch (e) {
      throw Exception('Error loading product: $e');
    }
  }

  Future<Map<String, dynamic>> loadReviews(String productId) async {
    try {
      final reviewsFuture = _ratingApi.getRatingsByProduct(productId);
      final statsFuture = _ratingApi.getProductRatingStats(productId);
      final userReviewFuture = _ratingApi.getUserRatingForProduct(productId);

      final results = await Future.wait([
        reviewsFuture,
        statsFuture,
        userReviewFuture,
      ], eagerError: true);

      return {
        'reviews': results[0] as List<Rating>,
        'stats': results[1] as RatingStats,
        'userReview': results[2] as Rating?,
      };
    } catch (e) {
      throw Exception('Error loading reviews: $e');
    }
  }

  Future<bool> submitReview({
    required String productId,
    required int selectedStars,
    required String? reviewText,
    required Rating? existingReview,
  }) async {
    try {
      final user = await _userApi.getCurrentUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đánh giá');
      }

      final rating = Rating(
        maSanPham: productId,
        maTaiKhoan: user.maTaiKhoan,
        soSao: selectedStars,
        noiDung: reviewText?.trim().isEmpty ?? true ? null : reviewText!.trim(),
      );

      if (existingReview != null && existingReview.soSao > 0) {
        return await _ratingApi.updateRating(rating);
      } else {
        return await _ratingApi.addRating(rating);
      }
    } catch (e) {
      throw Exception('Error submitting review: $e');
    }
  }

  Future<bool> deleteReview(String productId) async {
    try {
      return await _ratingApi.deleteRating(productId);
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }
}