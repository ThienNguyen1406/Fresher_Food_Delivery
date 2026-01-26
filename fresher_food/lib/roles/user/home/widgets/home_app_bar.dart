import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/provider/home_provider.dart';
import 'package:fresher_food/roles/user/widgets/avatar_with_menu_widget.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearch;
  final VoidCallback onResetSearch;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearch,
    required this.onResetSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      collapsedHeight: kToolbarHeight + 20,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Container(
        height: kToolbarHeight,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Xin chào,",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<Map<String, dynamic>>(
                    future: context.read<HomeProvider>().getUserInfo(),
                    builder: (context, snapshot) {
                      final userName = snapshot.data?['hoTen'] ?? 'Người dùng';
                      return Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: context.read<HomeProvider>().getUserInfo(),
              builder: (context, snapshot) {
                final avatarUrl = snapshot.data?['avatar'];
                final userName = snapshot.data?['tenTaiKhoan'] ?? 'Người dùng';
                return AvatarWithMenuWidget(
                  avatarUrl: avatarUrl,
                  userName: userName,
                  size: 40,
                );
              },
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm sản phẩm...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (value) => onSearch(),
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    onPressed: onResetSearch,
                  ),
                Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: provider.state.isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                        onPressed: onSearch,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
