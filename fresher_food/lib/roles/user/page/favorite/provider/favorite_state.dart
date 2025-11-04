import 'package:fresher_food/models/Product.dart';

class FavoriteState {
  final List<Product> favoriteProducts;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  FavoriteState({
    required this.favoriteProducts,
    required this.isLoading,
    required this.isLoggedIn,
    this.error,
  });

  FavoriteState copyWith({
    List<Product>? favoriteProducts,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
  }) {
    return FavoriteState(
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error ?? this.error,
    );
  }

  FavoriteState loading() {
    return copyWith(isLoading: true, error: null);
  }

  FavoriteState success(List<Product> products) {
    return copyWith(
      favoriteProducts: products,
      isLoading: false,
      error: null,
    );
  }

  FavoriteState errorState(String errorMessage) {
    return copyWith(
      isLoading: false,
      error: errorMessage,
    );
  }

  FavoriteState loggedIn(bool loggedIn) {
    return copyWith(isLoggedIn: loggedIn);
  }
}