import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:fresher_food/roles/user/page/account/provider/account_provider.dart';
import 'package:fresher_food/roles/user/page/cart/provider/cart_provider.dart';
import 'package:fresher_food/roles/user/page/favorite/provider/favorite_provider.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/provider/order_detail_provider.dart';
import 'package:fresher_food/roles/user/page/order/order_list/provider/order_list_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/page/splash/splash_screen.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:provider/provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
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
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrderDetailProvider()),
        ChangeNotifierProvider(create: (context) => OrderListProvider()),
        ChangeNotifierProvider(create: (context) => ProductDetailProvider()),
      ],
      child: MaterialApp(
        title: 'FreshFood App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
