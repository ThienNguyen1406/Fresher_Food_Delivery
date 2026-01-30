import 'package:flutter/material.dart';
import 'package:fresher_food/utils/app_localizations.dart';

class AdminChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final ThemeData theme;

  const AdminChatAppBar({
    super.key,
    required this.userName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            localizations.supportChat,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

