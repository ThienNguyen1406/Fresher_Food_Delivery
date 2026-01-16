import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/page/home_page.dart';
import 'package:fresher_food/roles/user/page/account/page/account_page.dart';
import 'package:fresher_food/roles/user/page/cart/page/cart_page.dart';
import 'package:fresher_food/roles/user/page/favorite/page/favorite_page.dart';
import 'package:fresher_food/roles/user/page/voucher/voucher_page.dart';
import 'package:fresher_food/roles/user/page/chat/chat_list_page.dart';
import 'package:fresher_food/roles/user/widgets/avatar_with_menu_widget.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fresher_food/widgets/quick_chatbot_dialog.dart';
import 'package:lottie/lottie.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final UserApi _userApi = UserApi();
  Map<String, dynamic>? _userInfo;
  String? _avatarUrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Position for draggable chatbot button
  Offset _chatbotPosition = const Offset(0, 0);
  bool _isInitialized = false;

  static final List<Widget> _pages = [
    const HomePage(),
    const VoucherPage(),
    const CartPage(),
    const ChatListPage(),
    const FavoritePage(),
    const AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _userApi.getUserInfo();
      setState(() {
        _userInfo = userInfo;
        _avatarUrl = userInfo['avatar'];
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handlePickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // TODO: Implement image upload
        // Tạm thời sử dụng file path local
        final imageUrl = pickedFile.path; // Cần upload lên server

        if (imageUrl.isNotEmpty && mounted) {
          final success = await _userApi.updateAvatar(imageUrl);
          if (success && mounted) {
            await _loadUserInfo();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật avatar thành công')),
            );
          }
        } else if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi upload ảnh')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAvatar() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc muốn xóa avatar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _userApi.deleteAvatar();
        if (success && mounted) {
          await _loadUserInfo();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa avatar thành công')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _userApi.logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;
    final fabSize = 72.0; // Larger size

    // Initialize position on first build
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Start at bottom right
            _chatbotPosition = Offset(
              screenSize.width - fabSize - 16,
              screenSize.height - 100 - fabSize,
            );
            _isInitialized = true;
          });
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedIndex == 5 ? _buildAccountAppBar(context) : null,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          // Draggable chatbot button
          if (_isInitialized)
            Positioned(
              left: _chatbotPosition.dx,
              top: _chatbotPosition.dy,
              child: _buildDraggableChatbotFAB(fabSize, screenSize),
            ),
        ],
      ),
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
                label: 'Home',
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
                        Icons.chat_bubble_outline,
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
                        Icons.chat_bubble,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: localizations.supportChat,
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
                        Icons.favorite_outline,
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
                        color: _selectedIndex == 5
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 24,
                        color: _selectedIndex == 5
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

  Widget _buildDrawer(BuildContext context) {
    return AvatarWithMenuWidget.buildDrawer(
      context: context,
      avatarUrl: _avatarUrl,
      userName: _userInfo?['tenTaiKhoan'] ?? 'Người dùng',
      onPickImage: _handlePickImage,
      onDeleteAvatar: _handleDeleteAvatar,
      onLogout: _handleLogout,
    );
  }

  AppBar _buildAccountAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(
        localizations.account,
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

  /// Draggable FloatingActionButton với Lottie animation cho Quick Chatbot
  Widget _buildDraggableChatbotFAB(double size, Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          double newX = _chatbotPosition.dx + details.delta.dx;
          double newY = _chatbotPosition.dy + details.delta.dy;
          
          // Constrain to screen bounds
          newX = newX.clamp(0.0, screenSize.width - size);
          newY = newY.clamp(0.0, screenSize.height - size);
          
          // Constrain to left or right side (within 20% of screen width from edges)
          final leftBoundary = screenSize.width * 0.2;
          final rightBoundary = screenSize.width * 0.8;
          
          if (newX < leftBoundary) {
            newX = 0.0; // Snap to left
          } else if (newX > rightBoundary - size) {
            newX = screenSize.width - size; // Snap to right
          }
          
          _chatbotPosition = Offset(newX, newY);
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => const QuickChatbotDialog(),
              );
            },
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Lottie.asset(
                'lib/assets/lottie/chatbot.json',
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
