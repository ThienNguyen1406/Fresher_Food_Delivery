import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

Uint8List? _decodeBase64InIsolate(String? base64String) {
  if (base64String == null || base64String.isEmpty) return null;
  try {
    return base64Decode(base64String);
  } catch (e) {
    return null;
  }
}

/// Widget hiển thị message bubble trong chat
class MessageBubble extends StatelessWidget {
  final Message message;
  final double screenWidth;
  final DateFormat timeFormat;

  const MessageBubble({
    super.key,
    required this.message,
    required this.screenWidth,
    required this.timeFormat,
  });

  static final _imageDataRegex = RegExp(r'\[IMAGE_DATA\](.*?)\[/IMAGE_DATA\]', dotAll: true);
  static final _productsDataRegex = RegExp(r'\[PRODUCTS_DATA\](.*?)\[/PRODUCTS_DATA\]', dotAll: true);
  static final _imageDataRemoveRegex = RegExp(r'\[IMAGE_DATA\].*?\[/IMAGE_DATA\]', dotAll: true);

  /// Parse message và hiển thị với products images nếu có
  Widget _buildMessageContent(String messageText, bool isFromUser) {
    final imageDataMatch = _imageDataRegex.firstMatch(messageText);
    final productsDataMatch = _productsDataRegex.firstMatch(messageText);
    
    String textMessage = messageText;
    if (imageDataMatch != null) {
      textMessage = textMessage.replaceAll(_imageDataRemoveRegex, '').trim();
    }
    if (productsDataMatch != null) {
      textMessage = textMessage.substring(0, productsDataMatch.start).trim();
    }
    
    String? userImageData;
    bool isImageFilePath = false;
    if (imageDataMatch != null && isFromUser) {
      try {
        userImageData = imageDataMatch.group(1)?.trim();
        if (userImageData != null && userImageData.length < 100 && userImageData.contains('/')) {
          isImageFilePath = true;
        }
      } catch (e) {
        print('Error parsing image data: $e');
      }
    }
    
    List<dynamic> productsWithImages = [];
    if (productsDataMatch != null) {
      try {
        final jsonStr = productsDataMatch.group(1)?.trim() ?? '';
        final productsData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final products = productsData['products'] as List<dynamic>? ?? [];
        
        productsWithImages = products.where((p) {
          final imageData = p['imageData'] as String?;
          return imageData != null && imageData.isNotEmpty;
        }).toList();
      } catch (e) {
        print('Error parsing products data: $e');
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userImageData != null && userImageData.isNotEmpty) ...[
          RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFromUser ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isImageFilePath
                    ? // 🔥 TỐI ƯU: Hiển thị từ file path ngay lập tức (không cần decode)
                      Builder(
                        builder: (context) {
                          try {
                            return Image.file(
                              File(userImageData!),
                              fit: BoxFit.cover,
                              cacheWidth: 200,
                              cacheHeight: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            );
                          } catch (e) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          }
                        },
                      )
                    : FutureBuilder<Uint8List?>(
                        future: compute(_decodeBase64InIsolate, userImageData),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              cacheWidth: 200,
                              cacheHeight: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            );
                          }
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
        if (textMessage.isNotEmpty)
          Text(
            textMessage,
            style: TextStyle(
              color: isFromUser ? Colors.white : Colors.grey.shade800,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        if (productsWithImages.isNotEmpty) ...[
          if (textMessage.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: productsWithImages.map((product) {
              final imageData = product['imageData'] as String?;
              
              if (imageData != null && imageData.isNotEmpty) {
                try {
                  return RepaintBoundary(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<Uint8List?>(
                          // 🔥 TỐI ƯU: Decode base64 trong isolate để không block UI thread
                          future: compute(_decodeBase64InIsolate, imageData),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                // 🔥 TỐI ƯU: Cache image để tránh decode lại
                                cacheWidth: 120,
                                cacheHeight: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error decoding image: $error');
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  );
                                },
                              );
                            }
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  print('Error displaying image: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    // TỐI ƯU: Sử dụng cached values thay vì tính toán lại
    final maxWidth = screenWidth * 0.75;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            Container(
              width: 36,
              height: 36,
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
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isFromUser
                    ? LinearGradient(
                        colors: [Colors.blue.shade500, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isFromUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromUser ? 20 : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageContent(message.noiDung, isFromUser),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(message.ngayGui),
                    style: TextStyle(
                      color: isFromUser
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

