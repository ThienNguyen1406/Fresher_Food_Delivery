import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/providers/splash_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState called');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('SplashScreen: _checkAuthStatus started');
    
    // Lấy provider
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    
    // Đợi provider khởi tạo xong
    while (!splashProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Kiểm tra xem đã hiển thị splash chưa
    if (splashProvider.hasShownSplash) {
      print('SplashScreen: Already shown, navigating directly...');
      // Đã hiển thị rồi, điều hướng ngay lập tức
      _navigateToNextScreen();
      return;
    }
    
    // Chưa hiển thị, hiển thị splash screen
    print('SplashScreen: First time showing splash');
    await Future.delayed(const Duration(seconds: 2));
    print('SplashScreen: Delay completed, checking auth status...');

    // Đánh dấu đã hiển thị splash
    await splashProvider.markSplashAsShown();
    print('SplashScreen: Marked splash as shown');

    if (!mounted) return;
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final isLoggedIn = await UserApi().isLoggedIn();
      print('SplashScreen: isLoggedIn = $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        final isAdmin = await UserApi().isAdmin();
        print('SplashScreen: isAdmin = $isAdmin');
        if (isAdmin) {
          print('SplashScreen: Navigating to admin dashboard');
          AppRoute.pushReplacement(context, AppRoute.adminDashboard);
        } else {
          print('SplashScreen: Navigating to main screen');
          AppRoute.pushReplacement(context, AppRoute.main);
        }
      } else {
        print('SplashScreen: Navigating to login screen');
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
    return Consumer<SplashProvider>(
      builder: (context, splashProvider, child) {
        // Nếu đã hiển thị splash rồi, hiển thị màn hình trống trong khi điều hướng
        if (splashProvider.hasShownSplash) {
          return const Scaffold(
            backgroundColor: Colors.green,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }
        
        // Hiển thị splash screen đầy đủ
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
      },
    );
  }
}
