import 'package:fresher_food/models/Category.dart';
import 'package:fresher_food/models/Product.dart';

class HomeState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<Category> categories;
  final String selectedCategoryId;
  final bool isLoading;
  final bool isSearching;
  final bool isLoadingCategories;
  final Set<String> favoriteProductIds;
  final String searchKeyword;

  const HomeState({
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.isLoading = true,
    this.isSearching = false,
    this.isLoadingCategories = true,
    this.favoriteProductIds = const {},
    this.searchKeyword = '',
  });

  HomeState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    List<Category>? categories,
    String? selectedCategoryId,
    bool? isLoading,
    bool? isSearching,
    bool? isLoadingCategories,
    Set<String>? favoriteProductIds,
    String? searchKeyword,
  }) {
    return HomeState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}