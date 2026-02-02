import 'package:flutter/material.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'dart:io';

/// Widget input area cho chat
class MessageInput extends StatelessWidget {
  final TextEditingController messageController;
  final File? selectedImage;
  final ValueNotifier<bool> isSendingNotifier;
  final ValueNotifier<bool> isUploadingFileNotifier;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const MessageInput({
    super.key,
    required this.messageController,
    required this.selectedImage,
    required this.isSendingNotifier,
    required this.isUploadingFileNotifier,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isUploadingFileNotifier,
              builder: (context, isUploading, _) {
                if (isUploading) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  );
                }
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.image,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    onPressed: onPickImage,
                    tooltip: 'Chọn ảnh để tìm kiếm',
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedImage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              selectedImage!,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Nút X để xóa ảnh
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: onRemoveImage,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Text input
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: selectedImage != null
                            ? 'Nhập mô tả về ảnh (tùy chọn)...'
                            : localizations.typeMessage,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nút send
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade500,
                    Colors.green.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSendingNotifier.value ? null : onSendMessage,
                  borderRadius: BorderRadius.circular(22),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isSendingNotifier,
                    builder: (context, isSending, _) {
                      return isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

