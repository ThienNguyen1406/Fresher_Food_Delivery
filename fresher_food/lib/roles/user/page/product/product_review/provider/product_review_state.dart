import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/models/Product.dart';

class ProductReviewState {
  final List<Rating> reviews;
  final RatingStats? ratingStats;
  final Rating? userReview;
  final Product? product;
  final bool isLoading;
  final bool isSubmitting;
  final int selectedStars;
  final bool isEditMode;

  const ProductReviewState({
    required this.reviews,
    this.ratingStats,
    this.userReview,
    this.product,
    required this.isLoading,
    required this.isSubmitting,
    required this.selectedStars,
    required this.isEditMode,
  });

  ProductReviewState copyWith({
    List<Rating>? reviews,
    RatingStats? ratingStats,
    Rating? userReview,
    Product? product,
    bool? isLoading,
    bool? isSubmitting,
    int? selectedStars,
    bool? isEditMode,
  }) {
    return ProductReviewState(
      reviews: reviews ?? this.reviews,
      ratingStats: ratingStats ?? this.ratingStats,
      userReview: userReview ?? this.userReview,
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedStars: selectedStars ?? this.selectedStars,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  factory ProductReviewState.initial() {
    return const ProductReviewState(
      reviews: [],
      ratingStats: null,
      userReview: null,
      product: null,
      isLoading: true,
      isSubmitting: false,
      selectedStars: 0,
      isEditMode: false,
    );
  }
}