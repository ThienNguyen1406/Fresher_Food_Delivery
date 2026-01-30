import 'package:flutter/material.dart';
import 'dart:convert';

/// Parse message và hiển thị hình ảnh sản phẩm nếu có [PRODUCTS_DATA]
/// Và hiển thị hình ảnh từ user nếu có [IMAGE_DATA]
class AdminMessageContent extends StatelessWidget {
  final String messageText;
  final bool isFromAdmin;
  final bool isFromUser;
  final ThemeData theme;

  const AdminMessageContent({
    super.key,
    required this.messageText,
    required this.isFromAdmin,
    required this.isFromUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Kiểm tra xem có [IMAGE_DATA] không (hình ảnh từ user)
    // Sử dụng dotAll: true để match cả newline trong base64
    final imageDataMatch = RegExp(r'\[IMAGE_DATA\](.*?)\[/IMAGE_DATA\]', dotAll: true).firstMatch(messageText);
    String? userImageData;
    String textMessage = messageText;
    
    if (imageDataMatch != null) {
      try {
        userImageData = imageDataMatch.group(1)?.trim();
        // Loại bỏ [IMAGE_DATA] tag khỏi text message - QUAN TRỌNG: phải loại bỏ trước khi hiển thị
        textMessage = textMessage.replaceAll(RegExp(r'\[IMAGE_DATA\].*?\[/IMAGE_DATA\]', dotAll: true), '').trim();
        // Debug: kiểm tra xem có extract được image data không
        if (userImageData != null && userImageData.isNotEmpty) {
          print('✅ Admin chat: Found IMAGE_DATA, length: ${userImageData.length}, isFromUser: $isFromUser');
        }
      } catch (e) {
        print('❌ Admin chat: Error parsing IMAGE_DATA: $e');
      }
    } else {
      // Debug: kiểm tra xem message có chứa [IMAGE_DATA] không
      if (messageText.contains('[IMAGE_DATA]')) {
        print('⚠️ Admin chat: Message contains [IMAGE_DATA] but regex did not match. Message length: ${messageText.length}');
        // Thử extract lại với cách khác
        final altMatch = RegExp(r'\[IMAGE_DATA\]([\s\S]*?)\[/IMAGE_DATA\]').firstMatch(messageText);
        if (altMatch != null) {
          userImageData = altMatch.group(1)?.trim();
          textMessage = textMessage.replaceAll(RegExp(r'\[IMAGE_DATA\][\s\S]*?\[/IMAGE_DATA\]'), '').trim();
          print('✅ Admin chat: Found IMAGE_DATA with alternative regex, length: ${userImageData?.length ?? 0}');
        }
      }
    }
    
    // Kiểm tra tag [PRODUCTS_DATA]
    final productsDataMatch =
        RegExp(r'\[PRODUCTS_DATA\](.*?)\[/PRODUCTS_DATA\]', dotAll: true)
            .firstMatch(textMessage);

    if (productsDataMatch != null) {
      try {
        // Phần text trước PRODUCTS_DATA (đã loại bỏ IMAGE_DATA tag)
        final displayText = textMessage.substring(0, productsDataMatch.start).trim();
        final jsonStr = productsDataMatch.group(1)?.trim() ?? '';

        final productsData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final products = productsData['products'] as List<dynamic>? ?? [];

        final productsWithImages = products.where((p) {
          final imageData = (p as Map<String, dynamic>)['imageData'] as String?;
          return imageData != null && imageData.isNotEmpty;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 FIX: Hiển thị hình ảnh từ user nếu có
            if (userImageData != null && userImageData.isNotEmpty) ...[
              _buildUserImage(userImageData),
            ],
            // Phần text trước PRODUCTS_DATA (đã loại bỏ IMAGE_DATA tag)
            if (displayText.isNotEmpty)
              Text(
                displayText,
                style: TextStyle(
                  color: isFromAdmin
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            if (productsWithImages.isNotEmpty) ...[
              if (displayText.isNotEmpty) const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productsWithImages.map((product) {
                  final p = product as Map<String, dynamic>;
                  final imageData = p['imageData'] as String?;

                  if (imageData != null && imageData.isNotEmpty) {
                    try {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(imageData),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } catch (_) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ],
          ],
        );
      } catch (_) {
        // Nếu lỗi parse, hiển thị text bình thường
      }
    }

    // 🔥 FIX: Hiển thị hình ảnh từ user nếu có (không có PRODUCTS_DATA)
    if (userImageData != null && userImageData.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserImage(userImageData),
          if (textMessage.isNotEmpty)
            Text(
              textMessage,
              style: TextStyle(
                color: isFromAdmin
                    ? Colors.white
                    : theme.textTheme.bodyLarge?.color,
                fontSize: 15,
                height: 1.4,
              ),
            ),
        ],
      );
    }
    
    // Mặc định: hiển thị text bình thường (đã loại bỏ IMAGE_DATA tag)
    // QUAN TRỌNG: Đảm bảo loại bỏ [IMAGE_DATA] tag ngay cả khi regex không match
    // (fallback cho trường hợp format khác)
    String finalText = textMessage;
    if (finalText.contains('[IMAGE_DATA]')) {
      // Thử loại bỏ lại nếu vẫn còn
      finalText = finalText.replaceAll(RegExp(r'\[IMAGE_DATA\].*?\[/IMAGE_DATA\]', dotAll: true), '').trim();
      // Nếu vẫn còn, thử cách khác (có thể có whitespace)
      if (finalText.contains('[IMAGE_DATA]')) {
        finalText = finalText.replaceAll(RegExp(r'\[IMAGE_DATA\][\s\S]*?\[/IMAGE_DATA\]'), '').trim();
      }
    }
    
    return Text(
      finalText,
      style: TextStyle(
        color: isFromAdmin
            ? Colors.white
            : theme.textTheme.bodyLarge?.color,
        fontSize: 15,
      ),
    );
  }

  Widget _buildUserImage(String userImageData) {
    try {
      final imageBytes = base64Decode(userImageData);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFromAdmin ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Admin chat: Error displaying image: $error');
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ Admin chat: Error decoding base64 image: $e');
      return Container(
        width: 200,
        height: 200,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
  }
}

