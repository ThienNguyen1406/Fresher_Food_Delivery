import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:image_picker/image_picker.dart';

class AvatarWithMenuWidget extends StatefulWidget {
  final String? avatarUrl;
  final String userName;
  final double size;
  final bool showMenu;

  const AvatarWithMenuWidget({
    super.key,
    this.avatarUrl,
    required this.userName,
    this.size = 40,
    this.showMenu = true,
  });

  @override
  State<AvatarWithMenuWidget> createState() => _AvatarWithMenuWidgetState();

  // Widget drawer để hiển thị menu
  static Widget buildDrawer({
    required BuildContext context,
    required String? avatarUrl,
    required String userName,
    required Function(ImageSource) onPickImage,
    required VoidCallback onDeleteAvatar,
    required VoidCallback onLogout,
  }) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header với avatar và thông tin user
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Hiển thị dialog chọn nguồn ảnh
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Chọn ảnh đại diện'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt, color: Colors.green),
                              title: const Text('Chụp ảnh'),
                              onTap: () {
                                Navigator.pop(context);
                                onPickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library, color: Colors.green),
                              title: const Text('Chọn từ thư viện'),
                              onTap: () {
                                Navigator.pop(context);
                                onPickImage(ImageSource.gallery);
                              },
                            ),
                            if (avatarUrl != null) ...[
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.orange),
                                title: const Text('Sửa avatar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  onPickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Xóa avatar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  onDeleteAvatar();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.blue),
            title: const Text('Giỏ hàng'),
            onTap: () {
              Navigator.pop(context);
              AppRoute.toCart(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.purple),
            title: const Text('Quản lý thẻ'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Quản lý thẻ'),
                  content: const Text('Chức năng quản lý thẻ sẽ được thêm vào phần thanh toán bằng thẻ tín dụng.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('Thông tin người dùng'),
            onTap: () {
              Navigator.pop(context);
              AppRoute.toProfileEdit(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

class _AvatarWithMenuWidgetState extends State<AvatarWithMenuWidget> {
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.avatarUrl;
  }

  @override
  void didUpdateWidget(AvatarWithMenuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _currentAvatarUrl = widget.avatarUrl;
    }
  }

  void _showAvatarMenu(BuildContext context) {
    if (!widget.showMenu) return;

    // Mở drawer từ Scaffold - tìm ScaffoldState từ context root
    // Tìm ScaffoldState từ tất cả các ancestor
    final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
    
    if (scaffoldState != null) {
      scaffoldState.openDrawer();
    } else {
      // Nếu không tìm thấy, thử tìm từ root bằng maybeOf
      final rootScaffold = Scaffold.maybeOf(context);
      if (rootScaffold != null) {
        rootScaffold.openDrawer();
      } else {
        // Fallback: hiển thị bottom sheet
        _showFallbackMenu(context);
      }
    }
  }

  void _showFallbackMenu(BuildContext context) {
    // Fallback: hiển thị bottom sheet nếu không tìm thấy drawer
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.blue),
              title: const Text('Giỏ hàng'),
              onTap: () {
                Navigator.pop(context);
                AppRoute.toCart(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.purple),
              title: const Text('Quản lý thẻ'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Thông tin người dùng'),
              onTap: () {
                Navigator.pop(context);
                AppRoute.toProfileEdit(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (builderContext) => GestureDetector(
        onTap: () => _showAvatarMenu(builderContext),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.shade100,
            border: Border.all(
              color: Colors.green.shade300,
              width: 2,
            ),
          ),
          child: _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _currentAvatarUrl!,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: widget.size * 0.6,
                      color: Colors.green,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: widget.size * 0.6,
                  color: Colors.green,
                ),
        ),
      ),
    );
  }
}

