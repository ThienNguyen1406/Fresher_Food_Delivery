import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/favorite/provider/favorite_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_loading_screen.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_error_screen.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_login_required.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_empty_screen.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_item_widget.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_delete_dialog.dart';
import 'package:fresher_food/roles/user/page/favorite/widgets/favorite_snackbar_widgets.dart';


class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  void initState() {
    super.initState();
    // Không gọi initialize ở đây nữa, sẽ gọi trong build
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (context) => FavoriteProvider()..initialize(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Sản phẩm yêu thích',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: theme.textTheme.titleLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.iconTheme.color),
          shadowColor: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
          surfaceTintColor: theme.appBarTheme.surfaceTintColor,
        ),
        body: Consumer<FavoriteProvider>(
          builder: (context, provider, child) {
            // Xử lý các trạng thái loading, error, etc.
            if (provider.isLoading) {
              return const FavoriteLoadingScreen();
            }

            if (provider.hasError) {
              return FavoriteErrorScreen(provider: provider);
            }

            if (!provider.isLoggedIn) {
              return const FavoriteLoginRequired();
            }

            return _buildFavoriteList(provider);
          },
        ),
      ),
    );
  }


  Widget _buildFavoriteList(FavoriteProvider provider) {
    if (provider.isEmpty) {
      return const FavoriteEmptyScreen();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavorites(),
      backgroundColor: Colors.white,
      color: const Color(0xFFFF6B6B),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = provider.favoriteProducts[index];
          return FavoriteItemWidget(
            provider: provider,
            product: product,
            onDelete: () => _showDeleteConfirmation(provider, product),
          );
        },
      ),
    );
  }


  void _showDeleteConfirmation(FavoriteProvider provider, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FavoriteDeleteDialog(
          product: product,
          onConfirm: () => _removeFromFavorites(provider, product),
        );
      },
    );
  }

  Future<void> _removeFromFavorites(
      FavoriteProvider provider, Product product) async {
    try {
      await provider.removeFromFavorites(product);
      FavoriteSnackbarWidgets.showSuccess(
          context, 'Đã xóa "${product.tenSanPham}" khỏi yêu thích');
    } catch (e) {
      FavoriteSnackbarWidgets.showError(context, 'Lỗi khi xóa: $e');
    }
  }
}
