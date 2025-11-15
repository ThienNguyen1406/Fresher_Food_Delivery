import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/services/api/user_api.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final isLoggedIn = await UserApi().isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        final isAdmin = await UserApi().isAdmin();
        if (isAdmin) {
          AppRoute.pushReplacement(context, AppRoute.adminDashboard);
        } else {
          AppRoute.pushReplacement(context, AppRoute.main);
        }
      } else {
        AppRoute.pushReplacement(context, AppRoute.login);
      }
    } catch (e) {
      print('Error in splash screen: $e');
      // Nếu có lỗi, chuyển đến login screen
      if (!mounted) return;
      AppRoute.pushReplacement(context, AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'FreshFood',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
