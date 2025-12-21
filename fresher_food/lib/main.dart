import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:fresher_food/roles/user/page/account/provider/account_provider.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_provider.dart';
import 'package:fresher_food/roles/user/page/favorite/provider/favorite_provider.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/provider/order_detail_provider.dart';
import 'package:fresher_food/roles/user/page/order/order_list/provider/order_list_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/providers/theme_provider.dart';
import 'package:fresher_food/providers/language_provider.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import "package:flutter_stripe/flutter_stripe.dart";
import 'package:fresher_food/services/api/stripe_api.dart';

/// Override HttpClient để cho phép kết nối với SSL certificate không hợp lệ
/// 
/// Class này được sử dụng trong môi trường development để bỏ qua lỗi SSL certificate
/// LƯU Ý: Không nên sử dụng trong production
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// Hàm main - điểm khởi đầu của ứng dụng
/// 
/// Thực hiện các bước khởi tạo:
/// 1. Khởi tạo Flutter binding
/// 2. Cấu hình HttpOverrides để bỏ qua SSL certificate (chỉ dùng trong development)
/// 3. Khởi tạo Stripe payment gateway
/// 4. Chạy ứng dụng
void main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi sử dụng các Flutter APIs
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cấu hình để bỏ qua lỗi SSL certificate (chỉ dùng trong development)
  HttpOverrides.global = MyHttpOverrides();

  // Khởi tạo Stripe Payment Gateway - lấy publishable key từ backend
  try {
    print(' Initializing Stripe...');
    final stripeApi = StripeApi();
    final publishableKey = await stripeApi.getPublishableKey();

    if (publishableKey.isEmpty) {
      print(' Warning: Publishable key is empty');
    } else {
      // Thiết lập publishable key cho Stripe
      Stripe.publishableKey = publishableKey;
      print(
          ' Stripe initialized successfully with key: ${publishableKey.substring(0, 20)}...');
      
      // Khởi tạo native SDK của Stripe bằng cách gọi một method đơn giản
      try {
        // Gọi applySettings để đảm bảo native SDK được khởi tạo đúng cách
        await Stripe.instance.applySettings();
        print(' Stripe native SDK initialized via applySettings');
      } catch (e) {
        print(' Warning: Could not call applySettings: $e');
        // Đợi một chút để native SDK được khởi tạo tự động
        await Future.delayed(const Duration(milliseconds: 1000));
        print(' Stripe native SDK should be ready now (after delay)');
      }
    }
  } catch (e) {
    // Nếu không thể khởi tạo Stripe, app vẫn chạy nhưng tính năng thanh toán sẽ không hoạt động
    print(' Warning: Could not initialize Stripe: $e');
    print('Stripe payment will not be available');
  }

  // Chạy ứng dụng
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng
/// 
/// Quản lý:
/// - Tất cả các Provider (State Management)
/// - Theme (Light/Dark mode)
/// - Localization (Đa ngôn ngữ: Tiếng Việt, Tiếng Anh)
/// - Routing (Điều hướng giữa các màn hình)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Đăng ký tất cả các Provider để quản lý state trong toàn bộ ứng dụng
      providers: [
        // Provider cho API Service - xử lý các request HTTP
        Provider(create: (context) => ApiService()),
        // Provider cho Coupon API - quản lý mã giảm giá
        Provider<CouponApi>(create: (context) => CouponApi()),
        // Provider quản lý theme (Light/Dark mode)
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Provider quản lý ngôn ngữ (Tiếng Việt/Tiếng Anh)
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        // Provider quản lý danh sách yêu thích
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        // Provider quản lý trang chủ
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        // Provider quản lý tài khoản người dùng
        ChangeNotifierProvider(create: (context) => AccountProvider()),
        // Provider quản lý giỏ hàng
        ChangeNotifierProvider(create: (context) => CartProvider()),
        // Provider quản lý chi tiết đơn hàng
        ChangeNotifierProvider(create: (context) => OrderDetailProvider()),
        // Provider quản lý danh sách đơn hàng
        ChangeNotifierProvider(create: (context) => OrderListProvider()),
        // Provider quản lý chi tiết sản phẩm
        ChangeNotifierProvider(create: (context) => ProductDetailProvider()),
      ],
      // Sử dụng Consumer2 để lắng nghe thay đổi từ ThemeProvider và LanguageProvider
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'FreshFood App',
            // Theme cho chế độ sáng (Light mode)
            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: const Color(0xFF4CAF50), // Xanh lá Material Green 500
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFD),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4CAF50), // Xanh lá
                secondary: Color(0xFF66BB6A), // Xanh lá nhạt hơn
                tertiary: Color(0xFF2E7D32), // Xanh lá đậm
              ),
            ),
            // Theme cho chế độ tối (Dark mode)
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: const Color(0xFF4CAF50), // Xanh lá Material Green 500
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF66BB6A), // Xanh lá sáng hơn cho dark mode
                secondary: Color(0xFF4CAF50),
                tertiary: Color(0xFF2E7D32),
              ),
            ),
            // Chế độ theme hiện tại (Light/Dark/System)
            themeMode: themeProvider.themeMode,
            // Ngôn ngữ hiện tại
            locale: languageProvider.locale,
            // Các delegate để hỗ trợ đa ngôn ngữ
            localizationsDelegates: const [
              AppLocalizations.delegate, // Custom localization cho app
              GlobalMaterialLocalizations.delegate, // Material Design localization
              GlobalWidgetsLocalizations.delegate, // Widget localization
              GlobalCupertinoLocalizations.delegate, // Cupertino (iOS) localization
            ],
            // Các ngôn ngữ được hỗ trợ
            supportedLocales: const [
              Locale('vi', 'VN'), // Tiếng Việt
              Locale('en', 'US'), // Tiếng Anh
            ],
            // Route khởi đầu - màn hình splash
            initialRoute: AppRoute.splash,
            // Hàm tạo route động dựa trên tên route
            onGenerateRoute: AppRoute.generateRoute,
            // Ẩn banner debug ở góc trên bên phải
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
