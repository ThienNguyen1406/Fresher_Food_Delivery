import 'dart:convert';
import 'dart:io';
import 'package:fresher_food/utils/config.dart';
import 'package:http/http.dart' as http;

class ImageApi {
  // RAG Service URL (Python service)
  final String _ragServiceUrl = AppConfig.ragServiceUrl ?? 'http://localhost:8000';

  /// Upload ảnh và tạo embedding vector
  Future<Map<String, dynamic>?> uploadImage(
    File imageFile, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/images/upload'),
      );

      // Thêm metadata nếu có
      if (metadata != null) {
        request.fields['metadata'] = jsonEncode(metadata);
      }

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
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
        print('Error uploading image: ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception uploading image: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> uploadImagesBatch(
    List<File> imageFiles, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return [];
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/images/upload/multiple'),
      );

      // Thêm metadata nếu có
      if (metadata != null) {
        request.fields['metadata'] = jsonEncode(metadata);
      }

      // Thêm tất cả ảnh với cùng field name 'files'
      for (final imageFile in imageFiles) {
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'files',  // FastAPI expects 'files' for List[UploadFile]
          fileStream,
          fileLength,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 60 + (imageFiles.length * 5)), // Timeout tăng theo số lượng ảnh
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error uploading images batch: ${response.statusCode} - ${response.body}');
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Exception uploading images batch: $e');
      return [];
    }
  }

  /// Tìm kiếm ảnh tương tự
  ///
  /// Quy trình:
  /// 1. Upload ảnh query
  /// 2. Tạo embedding vector từ ảnh query
  /// 3. Tìm kiếm trong Vector Database các ảnh có embedding tương tự
  /// 4. Trả về danh sách ảnh tương tự
  ///
  /// Parameters:
  /// - imageFile: Ảnh query để tìm kiếm
  /// - topK: Số lượng kết quả trả về (mặc định: 5)
  ///
  /// Returns:
  /// - results: Danh sách ảnh tương tự với similarity score
  Future<Map<String, dynamic>?> searchSimilarImages(
    File imageFile, {
    int topK = 5,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/images/search?top_k=$topK'),
      );

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
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
        print('Error searching images: ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception searching images: $e');
      return null;
    }
  }

  /// Lấy danh sách tất cả ảnh đã upload
  Future<List<Map<String, dynamic>>> getImages() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_ragServiceUrl/api/images'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Exception getting images: $e');
      return [];
    }
  }

  /// Lấy thông tin chi tiết của một ảnh
  Future<Map<String, dynamic>?> getImageInfo(String imageId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_ragServiceUrl/api/images/$imageId'),
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
      print('Exception getting image info: $e');
      return null;
    }
  }

  /// Xóa ảnh và embedding của nó khỏi vector database
  Future<bool> deleteImage(String imageId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_ragServiceUrl/api/images/$imageId'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return res.statusCode == 200;
    } catch (e) {
      print('Exception deleting image: $e');
      return false;
    }
  }
}

