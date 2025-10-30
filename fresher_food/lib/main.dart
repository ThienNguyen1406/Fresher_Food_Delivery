import 'dart:io';

import 'package:flutter/material.dart';
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
        Provider<CouponApi>(create: (context) => CouponApi(),
        ),
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
