import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/main_screen.dart';
import 'package:fresher_food/roles/user/page/auth/auth_screen.dart';
import 'package:fresher_food/roles/user/page/splash/splash_screen.dart';
import 'package:fresher_food/roles/user/home/page/home_page.dart';
import 'package:fresher_food/roles/user/page/cart/page/cart_page.dart';
import 'package:fresher_food/roles/user/page/favorite/page/favorite_page.dart';
import 'package:fresher_food/roles/user/page/account/page/account_page.dart';
import 'package:fresher_food/roles/user/page/account/page/profile_edit_page.dart';
import 'package:fresher_food/roles/user/page/account/page/settings_page.dart';
import 'package:fresher_food/roles/user/page/account/page/support_center_page.dart';
import 'package:fresher_food/roles/user/page/account/page/contact_support_page.dart';
import 'package:fresher_food/roles/user/page/chat/chat_list_page.dart';
import 'package:fresher_food/roles/user/page/checkout/page/checkout_page.dart';
import 'package:fresher_food/roles/user/page/order/order_list/page/order_list_page.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/page/order_detail_page.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/page/product_detail_page.dart';
import 'package:fresher_food/roles/user/page/product/product_review/page/product_review_page.dart';
import 'package:fresher_food/roles/admin/dashboard/admin_dashboard_scren.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';

class AppRoute {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String favorite = '/favorite';
  static const String account = '/account';
  static const String profileEdit = '/profile-edit';
  static const String settings = '/settings';
  static const String supportCenter = '/support-center';
  static const String contactSupport = '/contact-support';
  static const String chatList = '/chat-list';
  static const String checkout = '/checkout';
  static const String orderList = '/order-list';
  static const String orderDetail = '/order-detail';
  static const String productDetail = '/product-detail';
  static const String productReview = '/product-review';
  static const String adminDashboard = '/admin-dashboard';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;
    final routeName = routeSettings.name;

    if (routeName == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    } else if (routeName == login) {
      return MaterialPageRoute(builder: (_) => const AuthScreen());
    } else if (routeName == main) {
      return MaterialPageRoute(builder: (_) => const MainScreen());
    } else if (routeName == home) {
      return MaterialPageRoute(builder: (_) => const HomePage());
    } else if (routeName == cart) {
      return MaterialPageRoute(builder: (_) => const CartPage());
    } else if (routeName == favorite) {
      return MaterialPageRoute(builder: (_) => const FavoritePage());
    } else if (routeName == account) {
      return MaterialPageRoute(builder: (_) => const AccountPage());
    } else if (routeName == profileEdit) {
      return MaterialPageRoute<bool>(builder: (_) => const ProfileEditPage());
    } else if (routeName == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsPage());
    } else if (routeName == supportCenter) {
      return MaterialPageRoute(builder: (_) => const SupportCenterPage());
    } else if (routeName == contactSupport) {
      return MaterialPageRoute(builder: (_) => const ContactSupportPage());
    } else if (routeName == chatList) {
      return MaterialPageRoute(builder: (_) => const ChatListPage());
    } else if (routeName == checkout) {
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => CheckoutProvider(
              selectedItems: args['selectedItems'] as List<CartItem>,
              totalAmount: args['totalAmount'] as double,
            ),
            child: CheckoutPage(
              selectedItems: args['selectedItems'] as List<CartItem>,
              totalAmount: args['totalAmount'] as double,
            ),
          ),
        );
      }
      throw Exception('CheckoutPage requires selectedItems and totalAmount');
    } else if (routeName == orderList) {
      return MaterialPageRoute(builder: (_) => const OrderListPage());
    } else if (routeName == orderDetail) {
      if (args is String) {
        return MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: args),
        );
      }
      throw Exception('OrderDetailPage requires orderId');
    } else if (routeName == productDetail) {
      if (args is String) {
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: args),
        );
      }
      throw Exception('ProductDetailPage requires productId');
    } else if (routeName == productReview) {
      if (args is String) {
        return MaterialPageRoute(
          builder: (_) => ProductReviewPage(productId: args),
        );
      }
      throw Exception('ProductReviewPage requires productId');
    } else if (routeName == adminDashboard) {
      return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route ${routeSettings.name} not found'),
          ),
        ),
      );
    }
  }

  // Navigation helper methods
  static Future<T?> push<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  static void popUntil(
      BuildContext context, bool Function(Route<dynamic>) predicate) {
    Navigator.popUntil(context, predicate);
  }

  // Specific navigation methods
  static Future<void> toProductDetail(
      BuildContext context, String productId) async {
    await push(context, productDetail, arguments: productId);
  }

  static Future<void> toOrderDetail(
      BuildContext context, String orderId) async {
    await push(context, orderDetail, arguments: orderId);
  }

  static Future<void> toCheckout(
    BuildContext context,
    List<CartItem> selectedItems,
    double totalAmount,
  ) async {
    await push(
      context,
      checkout,
      arguments: {
        'selectedItems': selectedItems,
        'totalAmount': totalAmount,
      },
    );
  }

  static Future<void> toProductReview(
      BuildContext context, String productId) async {
    await push(context, productReview, arguments: productId);
  }

  static Future<bool?> toProfileEdit(BuildContext context) async {
    return await push<bool>(context, profileEdit);
  }

  static Future<void> toSettings(BuildContext context) async {
    await push(context, settings);
  }

  static Future<void> toSupportCenter(BuildContext context) async {
    await push(context, supportCenter);
  }

  static Future<void> toContactSupport(BuildContext context) async {
    await push(context, contactSupport);
  }

  static Future<void> toChatList(BuildContext context) async {
    await push(context, chatList);
  }

  static Future<void> toOrderList(BuildContext context) async {
    await push(context, orderList);
  }

  static Future<void> toFavorite(BuildContext context) async {
    await push(context, favorite);
  }

  static Future<void> toCart(BuildContext context) async {
    await push(context, cart);
  }

  static Future<void> toLogin(BuildContext context) async {
    await pushAndRemoveUntil(context, login);
  }

  static Future<void> toMain(BuildContext context) async {
    await pushAndRemoveUntil(context, main);
  }

  static Future<void> toAdminDashboard(BuildContext context) async {
    await pushAndRemoveUntil(context, adminDashboard);
  }
}
