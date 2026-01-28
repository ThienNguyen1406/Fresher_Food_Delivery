import 'dart:convert';
import 'dart:io';
import 'package:fresher_food/utils/config.dart';
import 'package:http/http.dart' as http;

/// Product Embedding API Service
/// Pipeline: Product (Text + Image) → Embeddings → Vector Database (theo category)
/// 
/// Hỗ trợ:
/// - Embed product khi thêm sản phẩm mới
/// - Image to Image search
/// - Text to Image search
class ProductEmbeddingApi {
  // RAG Service URL (Python service)
  final String _ragServiceUrl = AppConfig.ragServiceUrl ?? 'http://localhost:8000';

  /// Embed product vào Vector Database
  /// 
  /// Khi thêm sản phẩm mới, tự động được embedding theo category
  /// 
  /// Parameters:
  /// - productData: Thông tin sản phẩm (product_id, product_name, description, category_id, etc.)
  /// - imageFile: Ảnh sản phẩm (tùy chọn)
  /// 
  /// Returns:
  /// - product_id: ID của sản phẩm đã embed
  /// - has_image: Có ảnh hay không
  /// - has_text: Có text hay không
  Future<Map<String, dynamic>?> embedProduct({
    required Map<String, dynamic> productData,
    File? imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/products/embed'),
      );

      // Thêm product data fields
      if (productData['product_id'] != null) {
        request.fields['product_id'] = productData['product_id'].toString();
      }
      request.fields['product_name'] = productData['product_name']?.toString() ?? '';
      if (productData['description'] != null) {
        request.fields['description'] = productData['description'].toString();
      }
      request.fields['category_id'] = productData['category_id']?.toString() ?? '';
      if (productData['category_name'] != null) {
        request.fields['category_name'] = productData['category_name'].toString();
      }
      if (productData['price'] != null) {
        request.fields['price'] = productData['price'].toString();
      }
      if (productData['unit'] != null) {
        request.fields['unit'] = productData['unit'].toString();
      }
      if (productData['origin'] != null) {
        request.fields['origin'] = productData['origin'].toString();
      }

      // Thêm ảnh nếu có
      if (imageFile != null) {
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error embedding product: ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception embedding product: $e');
      return null;
    }
  }

  /// Image to Image Search - Tìm kiếm sản phẩm bằng ảnh
  /// 
  /// Quy trình:
  /// 1. Upload ảnh query
  /// 2. Tạo image embedding từ ảnh query
  /// 3. Tìm kiếm trong Vector Database các products có image embedding tương tự
  /// 4. Filter theo category nếu có
  /// 
  /// Parameters:
  /// - imageFile: Ảnh query để tìm kiếm
  /// - categoryId: Filter theo category (tùy chọn)
  /// - topK: Số lượng kết quả (mặc định: 10)
  /// 
  /// Returns:
  /// - results: Danh sách sản phẩm tương tự với similarity scores
  Future<Map<String, dynamic>?> searchProductsByImage({
    required File imageFile,
    String? categoryId,
    int topK = 10,
  }) async {
    try {
      final uri = Uri.parse('$_ragServiceUrl/api/products/search/image')
          .replace(queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        'top_k': topK.toString(),
      });

      final request = http.MultipartRequest('POST', uri);

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error searching products by image: ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception searching products by image: $e');
      return null;
    }
  }

  /// Text to Image Search - Tìm kiếm sản phẩm bằng text
  /// 
  /// Quy trình:
  /// 1. Nhận text query (ví dụ: "bánh mì", "rau củ tươi")
  /// 2. Tạo text embedding từ query
  /// 3. Tìm kiếm trong Vector Database các products có text embedding tương tự
  /// 4. Filter theo category nếu có
  /// 
  /// Parameters:
  /// - query: Text query để tìm kiếm
  /// - categoryId: Filter theo category (tùy chọn)
  /// - topK: Số lượng kết quả (mặc định: 10)
  /// 
  /// Returns:
  /// - results: Danh sách sản phẩm tương tự với similarity scores
  Future<Map<String, dynamic>?> searchProductsByText({
    required String query,
    String? categoryId,
    int topK = 10,
  }) async {
    try {
      final requestBody = {
        'query': query,
        if (categoryId != null) 'category_id': categoryId,
        'top_k': topK,
      };

      final res = await http
          .post(
            Uri.parse('$_ragServiceUrl/api/products/search/text'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Error searching products by text: ${res.statusCode} - ${res.body}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Exception searching products by text: $e');
      return null;
    }
  }

  /// Lấy danh sách products trong một category từ Vector Database
  Future<Map<String, dynamic>?> getProductsByCategory(String categoryId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_ragServiceUrl/api/products/category/$categoryId'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Exception getting products by category: $e');
      return null;
    }
  }
}

