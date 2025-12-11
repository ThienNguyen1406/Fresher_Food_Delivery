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
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fresher_food/services/api/stripe_api.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Khởi tạo Stripe - lấy publishable key từ backend
  try {
    print(' Initializing Stripe...');
    final stripeApi = StripeApi();
    final publishableKey = await stripeApi.getPublishableKey();

    if (publishableKey.isEmpty) {
      print(' Warning: Publishable key is empty');
    } else {
      Stripe.publishableKey = publishableKey;
      print(
          ' Stripe initialized successfully with key: ${publishableKey.substring(0, 20)}...');
      
      // Khởi tạo native SDK bằng cách gọi một method đơn giản
      try {
        // Gọi applySettings để đảm bảo native SDK được khởi tạo
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
    print(' Warning: Could not initialize Stripe: $e');
    print('Stripe payment will not be available');
    // Vẫn chạy app nhưng Stripe sẽ không hoạt động
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => ApiService()),
        Provider<CouponApi>(
          create: (context) => CouponApi(),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrderDetailProvider()),
        ChangeNotifierProvider(create: (context) => OrderListProvider()),
        ChangeNotifierProvider(create: (context) => ProductDetailProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'FreshFood App',
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
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            initialRoute: AppRoute.splash,
            onGenerateRoute: AppRoute.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
