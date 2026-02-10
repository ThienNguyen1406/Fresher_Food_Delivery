import 'package:flutter/material.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/services/api/chatbot_action_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// Quick Chatbot Dialog - Hỏi đáp nhanh với RAG API
class QuickChatbotDialog extends StatefulWidget {
  const QuickChatbotDialog({super.key});

  @override
  State<QuickChatbotDialog> createState() => _QuickChatbotDialogState();
}

class _QuickChatbotDialogState extends State<QuickChatbotDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RagApi _ragApi = RagApi();
  final ChatbotActionApi _chatbotActionApi = ChatbotActionApi();
  final List<ChatMessage> _messages = [];
  final Map<String, bool> _loadingStates = {};
  bool _isLoading = false;
  bool _isWaitingForResponse = false;

  String _getFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String? _getFirstNullableString(Map<String, dynamic> map, List<String> keys) {
    final value = _getFirstString(map, keys);
    return value.isEmpty ? null : value;
  }

  num? _getFirstNum(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value;
      if (value is String && value.trim().isNotEmpty) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String _getProductId(Map<String, dynamic> product) {
    return _getFirstString(product, [
      'product_id',
      'productId',
      'maSanPham',
      'id',
    ]);
  }

  String _getProductName(Map<String, dynamic> product) {
    return _getFirstString(product, [
      'product_name',
      'productName',
      'tenSanPham',
      'name',
    ]);
  }

  int? _getProductStock(Map<String, dynamic> product) {
    final stock = _getFirstNum(product, [
      'soLuongTon',
      'soLuongTonKho',
      'tonKho',
      'stock',
      'quantity',
    ]);
    return stock?.toInt();
  }

  String _getProductImageUrl(Map<String, dynamic> product) {
    final url = _getFirstString(product, [
      'anh',
      'imageUrl',
      'image_url',
      'imageLink',
      'image_link',
      'image',
      'url',
    ]);
    return _isLikelyUrl(url) ? url : '';
  }

  String _getProductCategoryName(Map<String, dynamic> product) {
    return _getFirstString(product, [
      'tenDanhMuc',
      'categoryName',
      'category_name',
    ]);
  }

  bool _isLikelyUrl(String value) {
    final v = value.toLowerCase().trim();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  Widget _buildImageFromString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    if (_isLikelyUrl(trimmed)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          trimmed,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    // Support data URLs: data:image/png;base64,xxxx
    if (trimmed.startsWith('data:image')) {
      final parts = trimmed.split(',');
      if (parts.length == 2) {
        try {
          final bytes = base64Decode(parts[1]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }
    }

    // Fallback: assume raw base64 string
    try {
      final bytes = base64Decode(trimmed);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    // Thêm tin nhắn chào mừng
    _messages.add(ChatMessage(
      text:
          'Xin chào! Tôi có thể giúp gì cho bạn? Hãy đặt câu hỏi về sản phẩm, đơn hàng, hoặc bất kỳ thông tin nào bạn cần.',
      isFromBot: true,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Thêm câu hỏi của user vào danh sách
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isFromBot: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _isWaitingForResponse = true;
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      // Gọi RAG API để lấy câu trả lời
      final response = await _ragApi.askWithDocument(
        question: question,
        fileId: null, // Không cần file cụ thể, tìm trong tất cả documents
        maChat: null, // Không cần chat, đây là quick chat
        baseUrl: Constant().baseUrl,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWaitingForResponse = false;
        });

        if (response != null && response['answer'] != null) {
          // Lấy danh sách ảnh sản phẩm nếu có
          final products = response['products'] as List<dynamic>? ?? [];
          final images = products
              .map((p) => p as Map<String, dynamic>)
              .map((p) => _getFirstNullableString(p, [
                    'imageData',
                    'image_base64',
                    'imageBase64',
                    'image',
                    'imageUrl',
                    'image_url',
                    'imageLink',
                    'image_link',
                    'url',
                  ]))
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();

          _messages.add(ChatMessage(
            text: response['answer'] as String,
            isFromBot: true,
            timestamp: DateTime.now(),
            imageDataList: images,
            products: products.cast<Map<String, dynamic>>(),
          ));
        } else {
          _messages.add(ChatMessage(
            text:
                'Xin lỗi, tôi không thể tìm thấy thông tin để trả lời câu hỏi này. Vui lòng thử lại hoặc liên hệ với tại phần Chat để được hỗ trợ!',
            isFromBot: true,
            timestamp: DateTime.now(),
          ));
        }

        setState(() {});
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isWaitingForResponse = false;
        });
        _messages.add(ChatMessage(
          text: 'Đã xảy ra lỗi khi xử lý câu hỏi. Vui lòng thử lại sau.',
          isFromBot: true,
          timestamp: DateTime.now(),
        ));
        setState(() {});
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý ảo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hỏi đáp nhanh',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text('Bắt đầu cuộc trò chuyện...'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _messages.length + (_isWaitingForResponse ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isWaitingForResponse &&
                            index == _messages.length) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index], theme);
                      },
                    ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                                color: Colors.green.shade600, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendQuestion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade700
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isLoading ? null : _sendQuestion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isFromBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isFromBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isFromBot
                    ? null
                    : LinearGradient(
                        colors: [Colors.green.shade500, Colors.green.shade600],
                      ),
                color: message.isFromBot ? Colors.white : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isFromBot
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomRight: message.isFromBot
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message),
            ),
          ),
          if (!message.isFromBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

    /// Hiển thị text + ảnh (nếu quick chatbot trả về sản phẩm có image data/url)
  Widget _buildMessageContent(ChatMessage message) {
    final textWidget = Text(
      message.text,
      style: TextStyle(
        color: message.isFromBot ? Colors.black87 : Colors.white,
        fontSize: 14,
        height: 1.4,
      ),
    );

    // Nếu không có ảnh và không có sản phẩm, chỉ hiển thị text
    if (message.imageDataList.isEmpty && message.products.isEmpty) {
      return textWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        textWidget,
        if (message.imageDataList.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.imageDataList.map((base64Str) {
              return _buildImageFromString(base64Str);
            }).toList(),
          ),
        ],
        // 🔥 NEW: Action buttons cho từng sản phẩm
        if (message.products.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...message.products
              .map((product) => _buildProductActionButtons(product)),
        ],
      ],
    );
  }

  Widget _buildProductActionButtons(Map<String, dynamic> product) {
    final productId = _getProductId(product);
    final productName = _getProductName(product);
    final price = _getFirstNum(product, [
      'price',
      'gia',
      'donGia',
    ]);
    final stock = _getProductStock(product);
    final isOutOfStock = stock != null && stock <= 0;
    final isLoading = _loadingStates[productId] ?? false;

    if (productId.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(
              '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (stock != null) ...[
            const SizedBox(height: 4),
            Text(
              stock <= 0 ? 'Hết hàng' : 'Còn: $stock',
              style: TextStyle(
                color: stock <= 0 ? Colors.red.shade600 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      (isLoading || isOutOfStock) ? null : () => _addToCart(product),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Thêm vào giỏ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (isLoading || isOutOfStock) ? null : () => _buyNow(product),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.flash_on, size: 18),
                  label: const Text('Mua ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final productId = _getProductId(product);
    final productName = _getProductName(product);
    final stock = _getProductStock(product);

    // Get user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('maTaiKhoan') ?? prefs.getString('userId');

    if (productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã sản phẩm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (stock != null && stock <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết hàng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _loadingStates[productId] = true;
    });

    try {
      // Call backend API
      final result = await _chatbotActionApi.addToCartFromChatbot(
        userId: userId,
        productId: productId,
        quantity: 1,
      );

      if (!mounted) return;

      // Clear loading state
      setState(() {
        _loadingStates[productId] = false;
      });

      if (result['success'] == true) {
        // Success - close dialog and show success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Đã thêm $productName vào giỏ hàng'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Error - show error message but keep dialog open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStates[productId] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _buyNow(Map<String, dynamic> product) async {
    final productId = _getProductId(product);
    var productName = _getProductName(product);
    var stock = _getProductStock(product);
    var priceNum = _getFirstNum(product, ['price', 'gia', 'donGia', 'giaBan']);
    var imageUrl = _getProductImageUrl(product);
    var categoryName = _getProductCategoryName(product);

    // Get user ID
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('maTaiKhoan') ?? prefs.getString('userId');

    if (productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã sản phẩm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (priceNum == null || productName.isEmpty || stock == null || imageUrl.isEmpty) {
      try {
        final productDetail = await ProductApi().getProductById(productId);
        if (productDetail != null) {
          productName = productName.isNotEmpty ? productName : productDetail.tenSanPham;
          priceNum = priceNum ?? productDetail.giaBan;
          stock = stock ?? productDetail.soLuongTon;
          imageUrl = imageUrl.isNotEmpty ? imageUrl : productDetail.anh;
          categoryName = categoryName.isNotEmpty ? categoryName : productDetail.maDanhMuc;
        }
      } catch (_) {
        // Ignore and fallback to existing data
      }
    }

    if (priceNum == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được giá sản phẩm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (stock != null && stock <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết hàng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để mua hàng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final price = priceNum.toDouble();
    final item = CartItem(
      maGioHang: '',
      maSanPham: productId,
      soLuong: 1,
      tenSanPham: productName.isNotEmpty ? productName : 'Sản phẩm #$productId',
      giaBan: price,
      anh: _isLikelyUrl(imageUrl) ? imageUrl : '',
      soLuongTon: stock ?? 1,
      tenDanhMuc: categoryName,
      maTaiKhoan: userId,
      thanhTien: price,
      isSelected: true,
    );

    if (!mounted) return;
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await AppRoute.toCheckout(
      context,
      [item],
      item.thanhTien,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromBot;
  final DateTime timestamp;
  final List<String> imageDataList;
  final List<Map<String, dynamic>> products;

  ChatMessage({
    required this.text,
    required this.isFromBot,
    required this.timestamp,
    this.imageDataList = const [],
    this.products = const [],
  });
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
