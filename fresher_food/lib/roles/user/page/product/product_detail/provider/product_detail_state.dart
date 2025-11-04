import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/models/Rating.dart';

class ProductDetailState {
  final Product? product;
  final bool isLoading;
  final String errorMessage;
  final int quantity;
  final bool isFavorite;
  final List<Rating> ratings;
  final RatingStats ratingStats;
  final bool isLoadingRatings;
  final bool hasUserRated;
  final Rating? userRating;

  ProductDetailState({
    this.product,
    this.isLoading = true,
    this.errorMessage = '',
    this.quantity = 1,
    this.isFavorite = false,
    this.ratings = const [],
    RatingStats? ratingStats, // nullable parameter
    this.isLoadingRatings = false,
    this.hasUserRated = false,
    this.userRating,
  }) : ratingStats = ratingStats ??
            RatingStats(
              averageRating: 0.0,
              totalRatings: 0,
            ); // default initialization

  ProductDetailState copyWith({
    Product? product,
    bool? isLoading,
    String? errorMessage,
    int? quantity,
    bool? isFavorite,
    List<Rating>? ratings,
    RatingStats? ratingStats,
    bool? isLoadingRatings,
    bool? hasUserRated,
    Rating? userRating,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      quantity: quantity ?? this.quantity,
      isFavorite: isFavorite ?? this.isFavorite,
      ratings: ratings ?? this.ratings,
      ratingStats: ratingStats ?? this.ratingStats,
      isLoadingRatings: isLoadingRatings ?? this.isLoadingRatings,
      hasUserRated: hasUserRated ?? this.hasUserRated,
      userRating: userRating ?? this.userRating,
    );
  }

  ProductDetailState loading() {
    return copyWith(
      isLoading: true,
      errorMessage: '',
    );
  }

  ProductDetailState success(Product product) {
    return copyWith(
      product: product,
      isLoading: false,
      errorMessage: '',
    );
  }

  ProductDetailState error(String errorMessage) {
    return copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    );
  }

  ProductDetailState updateQuantity(int quantity) {
    return copyWith(quantity: quantity);
  }

  ProductDetailState toggleFavorite(bool isFavorite) {
    return copyWith(isFavorite: isFavorite);
  }

  ProductDetailState loadingRatings() {
    return copyWith(isLoadingRatings: true);
  }

  ProductDetailState ratingsSuccess({
    required RatingStats ratingStats,
    required List<Rating> ratings,
    required Rating? userRating,
  }) {
    return copyWith(
      ratingStats: ratingStats,
      ratings: ratings,
      userRating: userRating,
      hasUserRated: userRating != null && userRating.soSao > 0,
      isLoadingRatings: false,
    );
  }

  ProductDetailState ratingsError() {
    return copyWith(isLoadingRatings: false);
  }

  ProductDetailState updateUserRating(Rating rating) {
    return copyWith(
      userRating: rating,
      hasUserRated: true,
    );
  }

  ProductDetailState removeUserRating() {
    return copyWith(
      userRating: null,
      hasUserRated: false,
    );
  }
}
