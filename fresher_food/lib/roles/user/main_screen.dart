import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/page/home_page.dart';
import 'package:fresher_food/roles/user/page/account/page/account_page.dart';
import 'package:fresher_food/roles/user/page/cart/page/cart_page.dart';
import 'package:fresher_food/roles/user/page/favorite/page/favorite_page.dart';
import 'package:fresher_food/roles/user/page/voucher/voucher_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const HomePage(),
    const VoucherPage(),
    const CartPage(),
    const FavoritePage(),
    const AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _selectedIndex == 4 ? _buildAccountAppBar(context) : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.cardColor,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: theme.unselectedWidgetColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: theme.unselectedWidgetColor,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 0
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        size: 24,
                        color: _selectedIndex == 0
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 1
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        size: 24,
                        color: _selectedIndex == 1
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.explore,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Vouchers',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 2
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 24,
                        color: _selectedIndex == 2
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 3
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 24,
                        color: _selectedIndex == 3
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 4
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 24,
                        color: _selectedIndex == 4
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAccountAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Tài khoản',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.titleLarge?.color,
        ),
      ),
      backgroundColor:
          theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }
}
