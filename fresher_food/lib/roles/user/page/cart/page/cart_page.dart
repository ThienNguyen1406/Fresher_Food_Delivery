import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_loading_screen.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_login_required.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_empty_screen.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_item_widget.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_checkout_bar.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/stock_warning_dialog.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/delete_confirmation_dialog.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/cart_snackbar_widgets.dart';
import 'package:fresher_food/roles/user/page/cart/widgets/zero_quantity_dialog.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';

/// Màn hình giỏ hàng - quản lý sản phẩm trong giỏ hàng
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  /// Khối khởi tạo: Load dữ liệu giỏ hàng từ provider
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  /// Khối chức năng: Hiển thị cảnh báo khi số lượng vượt quá tồn kho
  void _showStockWarning(CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StockWarningDialog(item: item);
      },
    );
  }

  /// Khối chức năng: Hiển thị dialog xác nhận xóa sản phẩm
  void _showDeleteConfirmation(CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(cartItem: cartItem);
      },
    ).then((confirmed) {
      if (confirmed == true) {
        _removeFromCart(cartItem);
      }
    });
  }

  /// Khối chức năng: Xóa sản phẩm khỏi giỏ hàng
  Future<void> _removeFromCart(CartItem cartItem) async {
    final provider = context.read<CartProvider>();
    final success =
        await provider.removeFromCart(cartItem.maSanPham, cartItem.tenSanPham);
    if (success) {
      CartSnackbarWidgets.showSuccess(
          context, 'Đã xóa "${cartItem.tenSanPham}" khỏi giỏ hàng');
    } else {
      CartSnackbarWidgets.showError(context, 'Lỗi khi xóa sản phẩm');
    }
  }

  /// Khối chức năng: Cập nhật số lượng sản phẩm trong giỏ hàng
  /// - Kiểm tra số lượng hợp lệ
  /// - Kiểm tra tồn kho
  /// - Cập nhật lên server
  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
    final provider = context.read<CartProvider>();

    if (newQuantity <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => const ZeroQuantityDialog(),
      );

      if (confirm == true) {
        await _removeFromCart(cartItem);
      }
      return;
    }

    // Kiểm tra số lượng tồn kho
    if (newQuantity > cartItem.soLuongTon) {
      _showStockWarning(cartItem);
      return;
    }

    final success = await provider.updateQuantity(cartItem, newQuantity);
    if (!success) {
      CartSnackbarWidgets.showError(context, 'Lỗi khi cập nhật số lượng');
    }
  }

  /// Khối chức năng: Xử lý thanh toán - chuyển đến màn hình checkout
  void _handleCheckout(CartProvider provider) {
    if (provider.state.selectedItems.isEmpty) {
      CartSnackbarWidgets.showError(
          context, 'Vui lòng chọn ít nhất một sản phẩm để thanh toán');
      return;
    }

    // Kiểm tra số lượng tồn kho trước khi chuyển trang
    if (!provider.checkStockBeforeCheckout()) {
      final problematicItems = provider.getProblematicItems();
      if (problematicItems.isNotEmpty) {
        _showStockWarning(problematicItems.first);
      }
      return;
    }

    // Điều hướng đến trang thanh toán
    AppRoute.toCheckout(
      context,
      provider.state.selectedItems,
      provider.state.selectedTotal,
    ).then((_) {
      provider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Giỏ hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.textTheme.titleLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          return state.isLoading
              ? const CartLoadingScreen()
              : state.isLoggedIn
                  ? _buildCartContent(provider)
                  : const CartLoginRequired();
        },
      ),
    );
  }

  Widget _buildCartContent(CartProvider provider) {
    final state = provider.state;

    if (state.cartItems.isEmpty) {
      return const CartEmptyScreen();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cartItem = state.cartItems[index];
              return CartItemWidget(
                cartItem: cartItem,
                provider: provider,
                onUpdateQuantity: _updateQuantity,
                onDelete: (item) => _showDeleteConfirmation(item),
              );
            },
          ),
        ),
        CartCheckoutBar(
          provider: provider,
          onCheckout: () => _handleCheckout(provider),
        ),
      ],
    );
  }
}
