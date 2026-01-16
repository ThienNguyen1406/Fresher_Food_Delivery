import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/roles/user/home/provider/home_services.dart';
import 'package:fresher_food/roles/user/home/provider/home_states.dart';


class HomeProvider with ChangeNotifier {
  final HomeService _homeService = HomeService();
  
  HomeState _state = const HomeState();
  HomeState get state => _state;

  // Banner state
  int _currentBanner = 0;
  int get currentBanner => _currentBanner;
  
  void setCurrentBanner(int index) {
    _currentBanner = index;
    notifyListeners();
  }

  // Initialize data
  Future<void> initializeData() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
      _loadFavorites(),
    ]);
  }

  // Categories
  Future<void> fetchCategories() async {
    try {
      final categories = await _homeService.getCategories();
      _state = _state.copyWith(
        categories: categories,
        isLoadingCategories: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoadingCategories: false);
      notifyListeners();
      rethrow;
    }
  }

  // Products
  Future<void> fetchProducts() async {
    try {
      final products = await _homeService.getProducts();
      _state = _state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    _state = _state.copyWith(
      isLoading: true,
      selectedCategoryId: categoryId,
      searchKeyword: '',
    );
    notifyListeners();

    try {
      List<Product> categoryProducts;
      
      if (categoryId == 'all') {
        categoryProducts = await _homeService.getProducts();
      } else {
        categoryProducts = await _homeService.getProductsByCategory(categoryId);
      }
      
      _state = _state.copyWith(
        filteredProducts: categoryProducts,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      rethrow;
    }
  }

  // Search
  Future<void> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      if (_state.selectedCategoryId == 'all') {
        _state = _state.copyWith(
          filteredProducts: _state.products,
          isSearching: false,
          searchKeyword: '',
        );
      } else {
        await fetchProductsByCategory(_state.selectedCategoryId);
      }
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isSearching: true, searchKeyword: keyword);
    notifyListeners();

    try {
      final searchResults = await _homeService.searchProducts(keyword);
      _state = _state.copyWith(
        filteredProducts: searchResults,
        isSearching: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isSearching: false);
      notifyListeners();
      rethrow;
    }
  }

  void resetSearch() {
    _state = _state.copyWith(searchKeyword: '');
    notifyListeners();
    
    if (_state.selectedCategoryId == 'all') {
      _state = _state.copyWith(filteredProducts: _state.products);
      notifyListeners();
    } else {
      fetchProductsByCategory(_state.selectedCategoryId);
    }
  }

  // Favorites
  Future<void> _loadFavorites() async {
    try {
      final isLoggedIn = await _homeService.isLoggedIn();
      if (isLoggedIn) {
        final favorites = await _homeService.getFavorites();
        final favoriteIds = Set<String>.from(favorites.map((p) => p.maSanPham));
        _state = _state.copyWith(favoriteProductIds: favoriteIds);
        notifyListeners();
      }
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> toggleFavorite(Product product) async {
    try {
      final isLoggedIn = await _homeService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập để sử dụng tính năng này');
      }

      final isCurrentlyFavorite = _state.favoriteProductIds.contains(product.maSanPham);
      final newFavorites = Set<String>.from(_state.favoriteProductIds);
      
      if (isCurrentlyFavorite) {
        final success = await _homeService.removeFromFavorites(product.maSanPham);
        if (success) {
          newFavorites.remove(product.maSanPham);
        } else {
          throw Exception('Không thể xóa khỏi danh sách yêu thích');
        }
      } else {
        final success = await _homeService.addToFavorites(product.maSanPham);
        if (success) {
          newFavorites.add(product.maSanPham);
        } else {
          throw Exception('Không thể thêm vào danh sách yêu thích');
        }
      }
      
      _state = _state.copyWith(favoriteProductIds: newFavorites);
      notifyListeners();
      
    } catch (e) {
      rethrow;
    }
  }

  // Cart
  Future<void> addToCart(Product product) async {
    try {
      final isLoggedIn = await _homeService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập để sử dụng tính năng này');
      }

      final success = await _homeService.addToCart(product.maSanPham, 1);
      if (!success) {
        throw Exception('Không thể thêm sản phẩm vào giỏ hàng');
      }
    } catch (e) {
      rethrow;
    }
  }

  // User
  Future<Map<String, dynamic>> getUserInfo() async {
    return await _homeService.getUserInfo();
  }
}