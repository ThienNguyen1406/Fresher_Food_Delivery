import 'package:flutter/material.dart';
import 'package:fresher_food/utils/app_localizations.dart';

/// Widget AppBar cho chat detail page
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onDeleteChat;
  final VoidCallback onCreateNewChat;
  final VoidCallback onUploadDocument;
  final ValueNotifier<bool> isUploadingFileNotifier;

  const ChatAppBar({
    super.key,
    required this.onDeleteChat,
    required this.onCreateNewChat,
    required this.onUploadDocument,
    required this.isUploadingFileNotifier,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.supportChat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Hỗ trợ trực tuyến',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      actions: [
        // Menu options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            if (value == 'delete') {
              onDeleteChat();
            } else if (value == 'new_chat') {
              onCreateNewChat();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_chat',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Tạo chat mới'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa cuộc trò chuyện', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        // Nút upload file
        ValueListenableBuilder<bool>(
          valueListenable: isUploadingFileNotifier,
          builder: (context, isUploading, _) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: Colors.grey.shade700,
                  size: 22,
                ),
                onPressed: isUploading ? null : onUploadDocument,
                tooltip: 'Upload file để hỏi đáp',
              ),
            );
          },
        ),
      ],
    );
  }
}

