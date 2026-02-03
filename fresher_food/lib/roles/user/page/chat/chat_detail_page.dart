import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:fresher_food/roles/user/page/chat/provider/chat_provider.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/chat_app_bar.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/message_input.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/messages_list.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/loading_widget.dart';
import 'package:fresher_food/roles/user/page/chat/widgets/empty_widget.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void unawaited(Future<void> future) {}

class ChatDetailPage extends StatefulWidget {
  final String maChat;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.maChat,
    required this.currentUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
  
  /// Tạo provider cho chat detail page
  static Widget withProvider({
    required String maChat,
    required String currentUserId,
  }) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        maChat: maChat,
        currentUserId: currentUserId,
      ),
      builder: (context, child) {
        return ChatDetailPage(
          maChat: maChat,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  final ChatApi _chatApi = ChatApi();
  final RagApi _ragApi = RagApi();
  final CategoryApi _categoryApi = CategoryApi();
  final ProductApi _productApi = ProductApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatProvider? _chatProvider;
  
  double? _cachedScreenWidth;
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    
    // Provider sẽ tự động load messages và mark as read trong _initialize()
    // Đảm bảo mark as read ngay khi vào page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.chatService.markAsRead(
        maChat: widget.maChat,
        maNguoiDoc: widget.currentUserId,
      ).catchError((e) {
        print('Error marking as read in initState: $e');
        return false;
      });
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
      return;
    }

    final provider = _chatProvider;
    if (provider == null) return;

    // Đơn giản hóa: chỉ load more khi scroll gần top
    final currentPosition = _scrollController.position.pixels;
    final maxPosition = _scrollController.position.maxScrollExtent;
    final distanceFromTop = maxPosition - currentPosition;
    
    if (distanceFromTop <= 200 && 
        provider.hasMoreMessages && 
        !provider.isLoadingMore && 
        provider.messages.isNotEmpty) {
      provider.loadMoreMessages();
    }
  }

  /// Xóa cuộc trò chuyện
  Future<void> _deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await _chatApi.deleteChat(widget.maChat, widget.currentUserId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa cuộc trò chuyện'),
              backgroundColor: Colors.green,
            ),
          );
          // Quay lại màn hình trước
          Navigator.of(context).pop(true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa cuộc trò chuyện'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Tạo chat mới
  void _createNewChat() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    
    // Provider sẽ tự dispose khi widget bị remove
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final provider = _chatProvider;
    if (provider != null) {
      provider.setPageVisible(state == AppLifecycleState.resumed);
    }
  }

  // Các method _loadMessages, _loadMoreMessages, _waitForBotResponse, _startRefreshTimer 
  // đã được chuyển sang ChatProvider, không cần nữa


  Future<void> _sendMessage() async {
    final provider = _chatProvider;
    if (provider == null) return;
    
    final text = _messageController.text.trim();
    
    if (provider.selectedImagePath != null) {
      await _searchProductsByImage();
      return;
    }
    
    if (text.isEmpty || provider.isSending) return;
    
    _messageController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.jumpTo(0);
      }
    });

    try {
      if (provider.selectedFileId != null) {
        final response = await _ragApi.askWithDocument(
          question: text,
          fileId: provider.selectedFileId,
          maChat: widget.maChat,
          baseUrl: Constant().baseUrl,
        );

        if (response != null && mounted) {
          await provider.chatService.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );

          await provider.loadMessages(silent: true);
        } else {
          await provider.chatService.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: text,
          );
          await provider.loadMessages(silent: true);
        }
      } else {
        final success = await provider.sendMessage(text);
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
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

  Future<void> _uploadDocument() async {
    final provider = _chatProvider;
    if (provider == null) return;
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        provider.setUploadingFile(true);

        // Hiển thị loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Upload file lên RAG service
        final response = await provider.chatService.uploadDocument(file);

        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
        }

        if (response != null && mounted) {
          provider.setSelectedFile(response['file_id'], null);
          provider.setUploadingFile(false);

          // Gửi thông báo vào chat
          await provider.chatService.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: widget.currentUserId,
            loaiNguoiGui: 'User',
            noiDung: '📄 Đã upload file: ${result.files.single.name}',
          );

          await provider.loadMessages(silent: true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload thành công! Bạn có thể hỏi về file này.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          provider.setUploadingFile(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upload thất bại. Vui lòng thử lại.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      provider.setUploadingFile(false);
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _pickImageForSearch() async {
    final provider = _chatProvider;
    if (provider == null) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      provider.setSelectedFile(null, File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _removeSelectedImage() {
    final provider = _chatProvider;
    if (provider != null) {
      provider.setSelectedFile(null, null);
    }
  }

  Future<void> _searchProductsByImage() async {
    final provider = _chatProvider;
    if (provider == null) return;

    if (provider.selectedImagePath == null) return;

    final imageFile = File(provider.selectedImagePath!);
    final description = _messageController.text.trim();
    
    provider.setUploadingFile(true);
    
    String messageContent = description.isNotEmpty 
        ? '🖼️ $description'
        : '🖼️ Cửa hàng của bạn có sản phẩm này không ??';
    
    final tempMessageId = 'temp_image_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticImageMessage = Message(
      maTinNhan: tempMessageId,
      maChat: widget.maChat,
      maNguoiGui: widget.currentUserId,
      loaiNguoiGui: 'User',
      noiDung: '$messageContent\n\n[IMAGE_DATA]${imageFile.path}[/IMAGE_DATA]',
      ngayGui: DateTime.now(),
      daDoc: false,
    );
    
    // Add optimistic message through provider
    final currentMessages = List<Message>.from(provider.messages);
    currentMessages.insert(0, optimisticImageMessage);
    provider.updateMessages(currentMessages);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.jumpTo(0);
      }
    });

    String? imageBase64;
    try {
      final imageBytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
    }
    
    if (imageBase64 != null) {
      final updatedMessageContent = '$messageContent\n\n[IMAGE_DATA]$imageBase64[/IMAGE_DATA]';
      final updatedMessages = List<Message>.from(provider.messages);
      final messageIndex = updatedMessages.indexWhere((m) => m.maTinNhan == tempMessageId);
      if (messageIndex != -1) {
        updatedMessages[messageIndex] = Message(
          maTinNhan: tempMessageId,
          maChat: widget.maChat,
          maNguoiGui: widget.currentUserId,
          loaiNguoiGui: 'User',
          noiDung: updatedMessageContent,
          ngayGui: updatedMessages[messageIndex].ngayGui,
          daDoc: false,
        );
        provider.updateMessages(updatedMessages);
      }
    }

    try {
      final finalMessageContent = imageBase64 != null
          ? '$messageContent\n\n[IMAGE_DATA]$imageBase64[/IMAGE_DATA]'
          : messageContent;
      
      await provider.chatService.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: widget.currentUserId,
        loaiNguoiGui: 'User',
        noiDung: finalMessageContent,
      );
      
      // Clear ảnh và text sau khi gửi thành công
      provider.setSelectedFile(null, null);
      _messageController.clear();
      
      provider.setWaitingForBotResponse(true);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(0);
        }
      });

      final result = await provider.chatService.searchProductsByImage(
        imageFile: imageFile,
        userDescription: description,
        topK: 10,
      );

      // Đảm bảo clear ảnh sau khi xử lý xong (dù thành công hay thất bại)
      provider.setSelectedFile(null, null);
      provider.setUploadingAndWaiting(uploading: false, waiting: false);

      if (result != null && result['results'] != null && mounted) {
        final List<dynamic> products = result['results'];
        
        const double similarityThreshold = 0.65;
        
        if (products.isEmpty) {
          await _sendFallbackProducts();
        } else {
          final productsWithImages = await _fetchProductImages(products);
          
          productsWithImages.sort((a, b) {
            final simA = a['similarity'] as double? ?? 0.0;
            final simB = b['similarity'] as double? ?? 0.0;
            return simB.compareTo(simA);
          });
          
          final productsWithImage = productsWithImages.where((p) {
            final imageData = p['imageData'] as String?;
            return imageData != null && imageData.isNotEmpty;
          }).toList();
          
          final bestProduct = productsWithImages.isNotEmpty ? productsWithImages.first : null;
          final bestSimilarity = bestProduct?['similarity'] as double? ?? 0.0;
          
          List<Map<String, dynamic>> selectedProducts = [];
          String textMessage;
          
          if (bestSimilarity < similarityThreshold) {
            final categoryId = bestProduct?['categoryId'] as String?;
            if (categoryId != null && categoryId.isNotEmpty) {
              selectedProducts = await _getProductsByCategory(categoryId, limit: 3);
            }
            
            if (selectedProducts.isEmpty) {
              selectedProducts = await _getFallbackProducts(limit: 3);
            }
            
            textMessage = 'Bạn có thể tham khảo:\n';
            for (var i = 0; i < selectedProducts.length; i++) {
              final product = selectedProducts[i];
              final name = product['productName'] ?? 'N/A';
              final price = product['price'];
              textMessage += '${i + 1}. $name';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              }
              textMessage += '\n';
            }
          } else if (productsWithImage.isNotEmpty) {
            final bestProductWithImage = productsWithImage.first;
            final bestProductSimilarity = bestProductWithImage['similarity'] as double? ?? 0.0;
            
            if (bestProductSimilarity >= similarityThreshold) {
              selectedProducts = [bestProductWithImage];
              
              final productName = bestProductWithImage['productName'] as String?;
              final price = bestProductWithImage['price'];
              
              final displayName = (productName != null && productName.isNotEmpty && productName != 'N/A')
                  ? productName
                  : 'Sản phẩm';
              
              textMessage = 'Mình tìm thấy sản phẩm $displayName';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              } else {
                textMessage += ' (đang cập nhật giá)';
              }
            } else {
              selectedProducts = productsWithImage.take(3).toList();
              textMessage = 'Bạn có thể tham khảo:\n';
              for (var i = 0; i < selectedProducts.length; i++) {
                final product = selectedProducts[i];
                final name = product['productName'] ?? 'N/A';
                final price = product['price'];
                textMessage += '${i + 1}. $name';
                if (price != null) {
                  textMessage += ' - ${price.toStringAsFixed(0)}₫';
                }
                textMessage += '\n';
              }
            }
          } else {
            final productsWithImageForFallback = productsWithImages.where((p) {
              final imageData = p['imageData'] as String?;
              return imageData != null && imageData.isNotEmpty;
            }).take(3).toList();
            
            selectedProducts = productsWithImageForFallback.isNotEmpty 
                ? productsWithImageForFallback 
                : productsWithImages.take(3).toList();
            
            textMessage = 'Bạn có thể tham khảo:\n';
            for (var i = 0; i < selectedProducts.length; i++) {
              final product = selectedProducts[i];
              final name = product['productName'] ?? 'N/A';
              final price = product['price'];
              textMessage += '${i + 1}. $name';
              if (price != null) {
                textMessage += ' - ${price.toStringAsFixed(0)}₫';
              }
              textMessage += '\n';
            }
          }

          if (selectedProducts.isEmpty) {
            selectedProducts = await _getFallbackProducts(limit: 3);
            if (selectedProducts.isNotEmpty) {
              textMessage = 'Chúng tôi không có sản phẩm này, nhưng bạn có thể tham khảo:\n';
              for (var i = 0; i < selectedProducts.length; i++) {
                final product = selectedProducts[i];
                final name = product['productName'] ?? 'N/A';
                final price = product['price'];
                textMessage += '${i + 1}. $name';
                if (price != null) {
                  textMessage += ' - ${price.toStringAsFixed(0)}₫';
                }
                textMessage += '\n';
              }
            } else {
              textMessage = 'Xin lỗi, chúng tôi không tìm thấy sản phẩm tương tự.';
            }
          }

          final productsJson = jsonEncode({
            'products': selectedProducts,
            'hasImages': selectedProducts.any((p) => p['imageData'] != null && (p['imageData'] as String).isNotEmpty),
          });

          final messageContent = selectedProducts.isNotEmpty
              ? '$textMessage\n\n[PRODUCTS_DATA]$productsJson[/PRODUCTS_DATA]'
              : textMessage;

          final tempBotMessageId = 'bot_temp_${DateTime.now().millisecondsSinceEpoch}';
          final optimisticBotMessage = Message(
            maTinNhan: tempBotMessageId,
            maChat: widget.maChat,
            maNguoiGui: 'BOT',
            loaiNguoiGui: 'Admin',
            noiDung: messageContent,
            ngayGui: DateTime.now(),
            daDoc: false,
          );
          
          final currentMessages = List<Message>.from(provider.messages);
          currentMessages.insert(0, optimisticBotMessage);
          provider.updateMessages(currentMessages);
          
          provider.setWaitingForBotResponse(false);
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && mounted) {
              _scrollController.jumpTo(0);
            }
          });

          await _chatApi.sendMessage(
            maChat: widget.maChat,
            maNguoiGui: 'BOT',
            loaiNguoiGui: 'Admin',
            noiDung: messageContent,
          );
          
          await provider.loadMessages(silent: true);
          
          final updatedMessages = List<Message>.from(provider.messages);
          final hasRealMessage = updatedMessages.any((m) => 
            m.maNguoiGui == 'BOT' && 
            m.maTinNhan != tempBotMessageId &&
            m.noiDung.contains(textMessage.split('\n')[0])
          );
          
          if (hasRealMessage) {
            updatedMessages.removeWhere((m) => m.maTinNhan == tempBotMessageId);
            provider.updateMessages(updatedMessages);
          }
        }
      } else {
        provider.setWaitingForBotResponse(false);
        
        try {
          await _sendFallbackProducts();
    } catch (e) {
          try {
            final errorMessage = Message(
              maTinNhan: 'bot_error_${DateTime.now().millisecondsSinceEpoch}',
              maChat: widget.maChat,
              maNguoiGui: 'BOT',
              loaiNguoiGui: 'Admin',
              noiDung: 'Xin lỗi, chúng tôi không thể tìm kiếm sản phẩm lúc này. Vui lòng thử lại sau.',
              ngayGui: DateTime.now(),
              daDoc: false,
            );
            
            final currentMessages = List<Message>.from(provider.messages);
            currentMessages.insert(0, errorMessage);
            provider.updateMessages(currentMessages);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && mounted) {
                _scrollController.jumpTo(0);
              }
            });
            
            await _chatApi.sendMessage(
              maChat: widget.maChat,
              maNguoiGui: 'BOT',
              loaiNguoiGui: 'Admin',
              noiDung: errorMessage.noiDung,
            );
          } catch (e2) {
            print('Error sending error message: $e2');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tìm kiếm sản phẩm. Đã gửi sản phẩm gợi ý.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Đảm bảo clear ảnh khi có lỗi
      provider.setSelectedFile(null, null);
      provider.setUploadingAndWaiting(uploading: false, waiting: false);
      
      try {
        final errorMessage = Message(
          maTinNhan: 'bot_error_${DateTime.now().millisecondsSinceEpoch}',
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: 'Xin lỗi, có lỗi xảy ra khi tìm kiếm sản phẩm. Vui lòng thử lại sau.',
          ngayGui: DateTime.now(),
          daDoc: false,
        );
        
        final currentMessages = List<Message>.from(provider.messages);
        currentMessages.insert(0, errorMessage);
        provider.updateMessages(currentMessages);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            _scrollController.jumpTo(0);
          }
        });
        
        await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: errorMessage.noiDung,
        );
      } catch (e2) {
        print('Error sending error message: $e2');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      // Đảm bảo clear ảnh trong mọi trường hợp
      provider.setSelectedFile(null, null);
      provider.setUploadingAndWaiting(uploading: false, waiting: false);
    }
  }

  Map<String, String>? _cachedHeaders;
  
  /// Fetch product images từ backend
  Future<List<Map<String, dynamic>>> _fetchProductImages(List<dynamic> products) async {
    final baseUrl = Constant().baseUrl;
    
    // 🔥 TỐI ƯU: Cache headers
    if (_cachedHeaders == null) {
      _cachedHeaders = await ApiService().getHeaders();
    }
    final headers = _cachedHeaders!;
    
    try {
      // 🔥 TỐI ƯU: Fetch tất cả product info parallel thay vì tuần tự
      final productInfoFutures = products.map((product) async {
        final productId = product['product_id'] ?? '';
        final productName = product['product_name'] ?? 'N/A';
        final categoryId = product['category_id'] ?? '';
        final categoryName = product['category_name'] ?? '';
        final price = product['price'];
        final similarity = product['similarity'] ?? 0.0;
        
        String? imageData;
        String? imageMimeType;
        String? finalProductName = productName;
        
        if (productId.isNotEmpty) {
          try {
            // Gọi API để lấy thông tin product
            final productResponse = await http.get(
              Uri.parse('$baseUrl/Product/$productId'),
              headers: headers,
            ).timeout(const Duration(seconds: 5));
            
            if (productResponse.statusCode == 200) {
              final productData = jsonDecode(productResponse.body);
              final productInfo = productData is List && productData.isNotEmpty
                  ? productData[0]
                  : productData;
              
              // Lấy product name từ backend
              final backendProductName = productInfo['tenSanPham'] as String?;
              if (backendProductName != null && backendProductName.isNotEmpty) {
                finalProductName = backendProductName;
              }
              
              // Lấy image URL
              final imageUrl = productInfo['anh'] as String?;
              
              if (imageUrl != null && imageUrl.isNotEmpty) {
                // 🔥 TỐI ƯU: Download image parallel
                try {
                  // Kiểm tra URL hợp lệ
                  final uri = Uri.tryParse(imageUrl);
                  if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                    print('⚠️ Invalid image URL for product $productId: $imageUrl');
                  } else {
                    final imageResponse = await http.get(uri).timeout(
                      const Duration(seconds: 10), // Tăng timeout lên 10 giây
                    );
                    
                    if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                    imageData = base64Encode(imageResponse.bodyBytes);
                    imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
                      print('✅ Successfully downloaded image for product $productId (${imageData.length} bytes)');
                    } else {
                      print('⚠️ Failed to download image for product $productId: HTTP ${imageResponse.statusCode}, body length: ${imageResponse.bodyBytes.length}');
                    }
                  }
                } catch (e) {
                  print('❌ Error downloading image from $imageUrl for product $productId: $e');
                }
              } else {
                print('⚠️ No image URL for product $productId');
              }
            }
          } catch (e) {
            print('Error fetching product $productId: $e');
          }
        }
        
        // Đảm bảo product name không rỗng
        if (finalProductName == null || finalProductName.isEmpty || finalProductName == 'N/A') {
          finalProductName = 'Sản phẩm #$productId';
        }
        
        // Chỉ thêm imageData nếu không null và không empty
        final result = {
          'productId': productId,
          'productName': finalProductName,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'price': price,
          'similarity': similarity,
        };
        
        // Chỉ thêm imageData nếu có dữ liệu hợp lệ
        if (imageData != null && imageData.isNotEmpty) {
          result['imageData'] = imageData;
          if (imageMimeType != null) {
            result['imageMimeType'] = imageMimeType;
          }
        }
        
        return result;
      }).toList();
      
      final productsWithImages = await Future.wait(productInfoFutures);
      return productsWithImages;
    } catch (e) {
      print('Error fetching product images: $e');
      return [];
    }
  }

  /// Lấy sản phẩm theo category từ backend
  Future<List<Map<String, dynamic>>> _getProductsByCategory(String categoryId, {int limit = 3}) async {
    try {
      final products = await _categoryApi.getProductsByCategory(categoryId);
      
      if (products.isEmpty) {
        return [];
      }
      
      final limitedProducts = products.take(limit).toList();
      
      final productFutures = limitedProducts.map((product) async {
        String? imageData;
        String? imageMimeType;
        
        final imageUrl = product.anh;
        if (imageUrl.isNotEmpty) {
          try {
            // Kiểm tra URL hợp lệ
            final uri = Uri.tryParse(imageUrl);
            if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('⚠️ Invalid image URL for product ${product.maSanPham}: $imageUrl');
            } else {
              final imageResponse = await http.get(uri).timeout(
                const Duration(seconds: 10), // Tăng timeout lên 10 giây
              );
              
              if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
              imageData = base64Encode(imageResponse.bodyBytes);
              imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
                print('✅ Successfully downloaded image for product ${product.maSanPham} (${imageData.length} bytes)');
              } else {
                print('⚠️ Failed to download image for product ${product.maSanPham}: HTTP ${imageResponse.statusCode}');
              }
            }
          } catch (e) {
            print('❌ Error downloading image from $imageUrl for product ${product.maSanPham}: $e');
          }
        } else {
          print('⚠️ No image URL for product ${product.maSanPham}');
        }
        
        final result = {
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
        };
        
        // Chỉ thêm imageData nếu có dữ liệu hợp lệ
        if (imageData != null && imageData.isNotEmpty) {
          result['imageData'] = imageData;
          if (imageMimeType != null) {
            result['imageMimeType'] = imageMimeType;
          }
        }
        
        return result;
      }).toList();
      
      return await Future.wait(productFutures);
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  /// Lấy sản phẩm fallback (phổ biến) khi không tìm thấy
  Future<List<Map<String, dynamic>>> _getFallbackProducts({int limit = 3}) async {
    try {
      final products = await _productApi.getProducts();
      
      if (products.isEmpty) {
        return [];
      }
      
      products.sort((a, b) => b.soLuongTon.compareTo(a.soLuongTon));
      
      final limitedProducts = products.take(limit).toList();
      
      final productFutures = limitedProducts.map((product) async {
        String? imageData;
        String? imageMimeType;
        
        final imageUrl = product.anh;
        if (imageUrl.isNotEmpty) {
          try {
            // Kiểm tra URL hợp lệ
            final uri = Uri.tryParse(imageUrl);
            if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('⚠️ Invalid image URL for product ${product.maSanPham}: $imageUrl');
            } else {
              final imageResponse = await http.get(uri).timeout(
                const Duration(seconds: 10), // Tăng timeout lên 10 giây
              );
              
              if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
              imageData = base64Encode(imageResponse.bodyBytes);
              imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
                print('✅ Successfully downloaded image for product ${product.maSanPham} (${imageData.length} bytes)');
              } else {
                print('⚠️ Failed to download image for product ${product.maSanPham}: HTTP ${imageResponse.statusCode}');
              }
            }
                    } catch (e) {
            print('❌ Error downloading image from $imageUrl for product ${product.maSanPham}: $e');
          }
        } else {
          print('⚠️ No image URL for product ${product.maSanPham}');
        }
        
        final result = {
          'productId': product.maSanPham,
          'productName': product.tenSanPham,
          'categoryId': product.maDanhMuc,
          'price': product.giaBan,
        };
        
        // Chỉ thêm imageData nếu có dữ liệu hợp lệ
        if (imageData != null && imageData.isNotEmpty) {
          result['imageData'] = imageData;
          if (imageMimeType != null) {
            result['imageMimeType'] = imageMimeType;
          }
        }
        
        return result;
      }).toList();
      
      return await Future.wait(productFutures);
      } catch (e) {
      print('Error getting fallback products: $e');
      return [];
    }
  }

  /// Gửi sản phẩm fallback khi không tìm thấy kết quả
  Future<void> _sendFallbackProducts() async {
    try {
      final fallbackProducts = await _getFallbackProducts(limit: 3);
      
      if (fallbackProducts.isEmpty) {
        await _chatApi.sendMessage(
          maChat: widget.maChat,
          maNguoiGui: 'BOT',
          loaiNguoiGui: 'Admin',
          noiDung: 'Xin lỗi, chúng tôi không tìm thấy sản phẩm tương tự.',
        );
        return;
      }
      
      String textMessage = 'Chúng tôi không có sản phẩm này, nhưng bạn có thể tham khảo:\n';
      for (var i = 0; i < fallbackProducts.length; i++) {
        final product = fallbackProducts[i];
        final name = product['productName'] ?? 'N/A';
        final price = product['price'];
        textMessage += '${i + 1}. $name';
        if (price != null) {
          textMessage += ' - ${price.toStringAsFixed(0)}₫';
        }
        textMessage += '\n';
      }
      
      // Tạo JSON data cho products với images
      final productsJson = jsonEncode({
        'products': fallbackProducts,
        'hasImages': fallbackProducts.any((p) => p['imageData'] != null && (p['imageData'] as String).isNotEmpty),
      });
      
      // Tạo message content với [PRODUCTS_DATA] tag
      final messageContent = '$textMessage\n\n[PRODUCTS_DATA]$productsJson[/PRODUCTS_DATA]';
      
      // 🔥 OPTIMISTIC UPDATE: Hiển thị kết quả ngay lập tức trên UI
      final tempBotMessageId = 'bot_temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticBotMessage = Message(
        maTinNhan: tempBotMessageId,
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: messageContent,
        ngayGui: DateTime.now(),
        daDoc: false,
      );
      
      final provider = _chatProvider;
      if (provider == null) return;
      
      final currentMessages = List<Message>.from(provider.messages);
      currentMessages.insert(0, optimisticBotMessage);
      provider.updateMessages(currentMessages);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(0);
        }
      });
      
      // Gửi tin nhắn từ bot (background)
      await provider.chatService.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: messageContent,
      );
      
      // Load messages mới để thay thế optimistic message
      await provider.loadMessages(silent: true);
      
      // Xóa optimistic message nếu đã có message thật từ server
      final updatedMessages = List<Message>.from(provider.messages);
      final hasRealMessage = updatedMessages.any((m) => 
        m.maNguoiGui == 'BOT' && 
        m.maTinNhan != tempBotMessageId &&
        m.noiDung.contains(textMessage.split('\n')[0])
      );
      
      if (hasRealMessage) {
        updatedMessages.removeWhere((m) => m.maTinNhan == tempBotMessageId);
        provider.updateMessages(updatedMessages);
      }
      
      // 🔥 Đảm bảo typing indicator đã tắt sau khi gửi fallback products
      provider.setWaitingForBotResponse(false);
    } catch (e) {
      print('Error sending fallback products: $e');
      final provider = _chatProvider;
      if (provider != null) {
      // 🔥 Đảm bảo typing indicator đã tắt khi có lỗi
        provider.setWaitingForBotResponse(false);
        await provider.chatService.sendMessage(
        maChat: widget.maChat,
        maNguoiGui: 'BOT',
        loaiNguoiGui: 'Admin',
        noiDung: 'Xin lỗi, có lỗi xảy ra khi tìm kiếm sản phẩm.',
      );
      }
    } finally {
      final provider = _chatProvider;
      if (provider != null) {
        provider.setWaitingForBotResponse(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedScreenWidth == null) {
      _cachedScreenWidth = MediaQuery.of(context).size.width;
    }

    // Lấy provider từ context - sử dụng listen: false vì chúng ta sẽ dùng Consumer bên dưới
    final provider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider = provider;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: ChatAppBar(
        onDeleteChat: _deleteChat,
        onCreateNewChat: _createNewChat,
        onUploadDocument: _uploadDocument,
        isUploadingFileNotifier: ValueNotifier(provider.isUploadingFile),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                          // Nếu đang đợi bot response, luôn hiển thị MessagesList (có typing indicator)
                  if (provider.isWaitingForBotResponse) {
                            return MessagesList(
                              scrollController: _scrollController,
                      chatProvider: provider,
                              screenWidth: _cachedScreenWidth ?? 400,
                              timeFormat: _timeFormat,
                      onRefresh: () => provider.loadMessages(),
                            );
                          }
                          
                  if (provider.isLoading && provider.messages.isEmpty) {
                            return const LoadingWidget();
                          }
                  if (provider.messages.isEmpty) {
                            return const EmptyWidget();
                          }
                          return MessagesList(
                            scrollController: _scrollController,
                    chatProvider: provider,
                            screenWidth: _cachedScreenWidth ?? 400,
                            timeFormat: _timeFormat,
                    onRefresh: () => provider.loadMessages(),
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return MessageInput(
              messageController: _messageController,
                  selectedImage: provider.selectedImagePath != null 
                      ? File(provider.selectedImagePath!) 
                      : null,
                  isSendingNotifier: ValueNotifier(provider.isSending),
                  isUploadingFileNotifier: ValueNotifier(provider.isUploadingFile),
              onSendMessage: _sendMessage,
              onPickImage: _pickImageForSearch,
              onRemoveImage: _removeSelectedImage,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

