import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/home_page.dart';
import 'package:fresher_food/roles/user/page/account/account_screen.dart';
import 'package:fresher_food/roles/user/page/cart/cart_page.dart';
import 'package:fresher_food/roles/user/page/favorite/favorite_page.dart';
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
    return Scaffold(
      appBar: _selectedIndex == 4 ? _buildAccountAppBar() : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 0 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.store_outlined,
                    size: 24,
                    color: _selectedIndex == 0 ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 1 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    size: 24,
                    color: _selectedIndex == 1 ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.explore,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                label: 'Vouchers',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 2 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 24,
                    color: _selectedIndex == 2 ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 3 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    size: 24,
                    color: _selectedIndex == 3 ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedIndex == 4 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 24,
                    color: _selectedIndex == 4 ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAccountAppBar() {
    return AppBar(
      title: const Text(
        'Tài khoản',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }
}