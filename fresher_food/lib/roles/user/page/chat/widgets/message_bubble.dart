import 'package:flutter/material.dart';
import 'package:fresher_food/models/Chat.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';
import 'package:fresher_food/services/api/chatbot_action_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List? _decodeBase64InIsolate(String? base64String) {
  if (base64String == null || base64String.isEmpty) return null;
  try {
    return base64Decode(base64String);
  } catch (e) {
    return null;
  }
}

class _ProductActionButtons extends StatefulWidget {
  final Map<String, dynamic> product;

  const _ProductActionButtons({required this.product});

  @override
  State<_ProductActionButtons> createState() => _ProductActionButtonsState();
}

class _ProductActionButtonsState extends State<_ProductActionButtons> {
  bool _isLoading = false;

  String _formatPrice(num price) {
    return price
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('maTaiKhoan') ?? prefs.getString('userId');
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addToCart() async {
    final productId = _getProductId(widget.product);
    final productName = _getProductName(widget.product);
    final stock = _getProductStock(widget.product);

    if (productId.isEmpty) {
      _showSnack('Không tìm thấy mã sản phẩm');
      return;
    }

    if (stock != null && stock <= 0) {
      _showSnack('Sản phẩm đã hết hàng');
      return;
    }

    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      _showSnack('Vui lòng đăng nhập để thêm vào giỏ hàng');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ChatbotActionApi().addToCartFromChatbot(
        userId: userId,
        productId: productId,
        quantity: 1,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnack(
          result['message'] ?? 'Đã thêm $productName vào giỏ hàng',
          color: Colors.green,
        );
      } else {
        _showSnack(result['message'] ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    final productId = _getProductId(widget.product);
    var productName = _getProductName(widget.product);
    var stock = _getProductStock(widget.product);
    var priceNum =
        _getFirstNum(widget.product, ['price', 'gia', 'donGia', 'giaBan']);
    var imageUrl = _getProductImageUrl(widget.product);
    var categoryName = _getProductCategoryName(widget.product);

    if (productId.isEmpty) {
      _showSnack('Không tìm thấy mã sản phẩm');
      return;
    }

    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      _showSnack('Vui lòng đăng nhập để mua hàng');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (priceNum == null ||
          productName.isEmpty ||
          stock == null ||
          imageUrl.isEmpty) {
        final productDetail = await ProductApi().getProductById(productId);
        if (productDetail != null) {
          productName =
              productName.isNotEmpty ? productName : productDetail.tenSanPham;
          priceNum = priceNum ?? productDetail.giaBan;
          stock = stock ?? productDetail.soLuongTon;
          imageUrl = imageUrl.isNotEmpty ? imageUrl : productDetail.anh;
          categoryName =
              categoryName.isNotEmpty ? categoryName : productDetail.maDanhMuc;
        }
      }

      if (priceNum == null) {
        _showSnack('Không xác định được giá sản phẩm');
        return;
      }

      if (stock != null && stock <= 0) {
        _showSnack('Sản phẩm đã hết hàng');
        return;
      }

      final price = priceNum.toDouble();
      final item = CartItem(
        maGioHang: '',
        maSanPham: productId,
        soLuong: 1,
        tenSanPham:
            productName.isNotEmpty ? productName : 'Sản phẩm #$productId',
        giaBan: price,
        anh: _isLikelyUrl(imageUrl) ? imageUrl : '',
        soLuongTon: stock ?? 1,
        tenDanhMuc: categoryName,
        maTaiKhoan: userId,
        thanhTien: price,
        isSelected: true,
      );

      if (!mounted) return;
      await AppRoute.toCheckout(
        context,
        [item],
        item.thanhTien,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = _getProductId(widget.product);
    final productName = _getProductName(widget.product);
    final priceNum =
        _getFirstNum(widget.product, ['price', 'gia', 'donGia', 'giaBan']);
    final stock = _getProductStock(widget.product);
    final isOutOfStock = stock != null && stock <= 0;

    if (productId.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
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
            productName.isNotEmpty ? productName : 'Sản phẩm #$productId',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (priceNum != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatPrice(priceNum)}₫',
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
                      (_isLoading || isOutOfStock) ? null : _addToCart,
                  icon: _isLoading
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
                  onPressed: (_isLoading || isOutOfStock) ? null : _buyNow,
                  icon: _isLoading
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
}

/// Widget hiển thị message bubble trong chat
String _getFirstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
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

bool _isLikelyUrl(String value) {
  final v = value.toLowerCase().trim();
  return v.startsWith('http://') || v.startsWith('https://');
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

String _getProductImageValue(Map<String, dynamic> product) {
  return _getFirstString(product, [
    'imageData',
    'image_base64',
    'imageBase64',
    'image',
    'imageUrl',
    'image_url',
    'imageLink',
    'image_link',
    'url',
    'anh',
  ]);
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

String? _extractBase64FromDataUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('data:image')) {
    final parts = trimmed.split(',');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      return parts[1];
    }
  }
  return null;
}

Widget _buildProductImageWidget(String rawValue) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) return const SizedBox.shrink();

  if (_isLikelyUrl(trimmed)) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }

  final base64Str = _extractBase64FromDataUrl(trimmed) ?? trimmed;
  if (base64Str.isEmpty) return const SizedBox.shrink();

  return FutureBuilder<Uint8List?>(
    future: compute(_decodeBase64InIsolate, base64Str),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
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
          cacheWidth: 120,
          cacheHeight: 120,
          errorBuilder: (context, error, stackTrace) {
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
  );
}

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
    
    List<Map<String, dynamic>> products = [];
    List<Map<String, dynamic>> productsWithImages = [];
    if (productsDataMatch != null) {
      try {
        final jsonStr = productsDataMatch.group(1)?.trim() ?? '';
        final productsData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final parsedProducts = productsData['products'] as List<dynamic>? ?? [];
        products = parsedProducts.whereType<Map<String, dynamic>>().toList();

        productsWithImages = products.where((p) {
          final imageValue = _getProductImageValue(p);
          return imageValue.isNotEmpty;
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
              final imageValue = _getProductImageValue(product);
              if (imageValue.isEmpty) return const SizedBox.shrink();
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
                    child: _buildProductImageWidget(imageValue),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (!isFromUser && products.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...products.map((product) => _ProductActionButtons(product: product)),
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

