import 'package:fresher_food/services/api/chat_api.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/services/api/category_api.dart';
import 'package:fresher_food/services/api/product_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service xử lý business logic cho chat
class ChatService {
  final ChatApi _chatApi = ChatApi();
  final RagApi _ragApi = RagApi();
  final CategoryApi _categoryApi = CategoryApi();
  final ProductApi _productApi = ProductApi();

  /// Lấy danh sách messages
  Future<Map<String, dynamic>> getMessages({
    required String maChat,
    int limit = 30,
    String? beforeMessageId,
  }) async {
    return await _chatApi.getMessages(
      maChat: maChat,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  /// Gửi tin nhắn
  Future<bool> sendMessage({
    required String maChat,
    required String maNguoiGui,
    required String loaiNguoiGui,
    required String noiDung,
  }) async {
    return await _chatApi.sendMessage(
      maChat: maChat,
      maNguoiGui: maNguoiGui,
      loaiNguoiGui: loaiNguoiGui,
      noiDung: noiDung,
    );
  }

  /// Đánh dấu đã đọc
  Future<bool> markAsRead({
    required String maChat,
    required String maNguoiDoc,
  }) async {
    return await _chatApi.markAsRead(
      maChat: maChat,
      maNguoiDoc: maNguoiDoc,
    );
  }

  /// Xóa chat
  Future<bool> deleteChat(String maChat, String maNguoiDung) async {
    return await _chatApi.deleteChat(maChat, maNguoiDung);
  }

  /// Upload document
  Future<Map<String, dynamic>?> uploadDocument(File file) async {
    return await _ragApi.uploadDocument(file);
  }

  /// Search products by image
  Future<Map<String, dynamic>?> searchProductsByImage({
    required File imageFile,
    String? userDescription,
    int topK = 10,
  }) async {
    return await _ragApi.searchProductsByImage(
      imageFile: imageFile,
      userDescription: userDescription,
      topK: topK,
    );
  }

  /// Ask with document
  Future<Map<String, dynamic>?> askWithDocument({
    required String question,
    String? fileId,
    String? maChat,
    required String baseUrl,
  }) async {
    return await _ragApi.askWithDocument(
      question: question,
      fileId: fileId,
      maChat: maChat,
      baseUrl: baseUrl,
    );
  }

  /// Multi-Agent RAG query (text only) - Gọi qua C# backend
  Future<Map<String, dynamic>?> multiAgentQuery({
    required String query,
    String? userDescription,
    String? categoryId,
    int topK = 5,
    bool enableCritic = true,
    required String baseUrl,
  }) async {
    return await _ragApi.multiAgentQuery(
      query: query,
      userDescription: userDescription,
      categoryId: categoryId,
      topK: topK,
      enableCritic: enableCritic,
      baseUrl: baseUrl,
    );
  }

  /// Multi-Agent RAG query với image - Gọi qua C# backend
  Future<Map<String, dynamic>?> multiAgentQueryWithImage({
    required File imageFile,
    String? query,
    String? userDescription,
    String? categoryId,
    int topK = 5,
    bool enableCritic = true,
    required String baseUrl,
  }) async {
    return await _ragApi.multiAgentQueryWithImage(
      imageFile: imageFile,
      query: query,
      userDescription: userDescription,
      categoryId: categoryId,
      topK: topK,
      enableCritic: enableCritic,
      baseUrl: baseUrl,
    );
  }

  /// Fetch product images từ backend
  Future<List<Map<String, dynamic>>> fetchProductImages(List<dynamic> products) async {
    final baseUrl = Constant().baseUrl;
    
    // Cache headers
    final cachedHeaders = await ApiService().getHeaders();
    final headers = cachedHeaders;
    
    try {
      // Fetch tất cả product info parallel
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
            ).timeout(const Duration(seconds: 10));
            
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
                try {
                  // Kiểm tra URL hợp lệ
                  final uri = Uri.tryParse(imageUrl);
                  if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                    print('⚠️ Invalid image URL for product $productId: $imageUrl');
                  } else {
                    final imageResponse = await http.get(uri).timeout(
                      const Duration(seconds: 10),
                    );
                    
                    if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
                      imageData = base64Encode(imageResponse.bodyBytes);
                      imageMimeType = imageResponse.headers['content-type'] ?? 'image/jpeg';
                      print('✅ Successfully downloaded image for product $productId (${imageData.length} bytes)');
                    } else {
                      print('⚠️ Failed to download image for product $productId: HTTP ${imageResponse.statusCode}');
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

  /// Lấy sản phẩm theo category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId, {int limit = 3}) async {
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
            final uri = Uri.tryParse(imageUrl);
            if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('⚠️ Invalid image URL for product ${product.maSanPham}: $imageUrl');
            } else {
              final imageResponse = await http.get(uri).timeout(
                const Duration(seconds: 10),
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

  /// Lấy sản phẩm fallback (phổ biến)
  Future<List<Map<String, dynamic>>> getFallbackProducts({int limit = 3}) async {
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
            final uri = Uri.tryParse(imageUrl);
            if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('⚠️ Invalid image URL for product ${product.maSanPham}: $imageUrl');
            } else {
              final imageResponse = await http.get(uri).timeout(
                const Duration(seconds: 10),
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
}

