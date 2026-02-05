import 'dart:convert';
import 'dart:io';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/config.dart';
import 'package:http/http.dart' as http;

class RagApi {
  // RAG Service URL (Python service)
  final String _ragServiceUrl = AppConfig.ragServiceUrl ?? 'http://localhost:8000';

  /// Upload document để xử lý RAG
  Future<Map<String, dynamic>?> uploadDocument(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/documents/upload'),
      );

      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  }

  /// Retrieve context từ RAG service
  Future<Map<String, dynamic>?> retrieveContext({
    required String question,
    String? fileId,
    int topK = 5,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_ragServiceUrl/api/query/retrieve'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'question': question,
              'file_id': fileId,
              'top_k': topK,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      return null;
    }
  }

  /// Hỏi đáp với document (gọi qua ASP.NET backend)
  Future<Map<String, dynamic>?> askWithDocument({
    required String question,
    String? fileId,
    String? maChat,
    required String baseUrl,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      
      final res = await http
          .post(
            Uri.parse('$baseUrl/Chat/ask-with-document'),
            headers: headers,
            body: jsonEncode({
              'question': question,
              'fileId': fileId,
              'maChat': maChat,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách documents đã upload
  Future<List<dynamic>> getDocuments() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_ragServiceUrl/api/documents'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data;
    } catch (e) {
      return [];
    }
  }

  /// Xóa document
  Future<bool> deleteDocument(String fileId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_ragServiceUrl/api/documents/$fileId'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Tìm kiếm sản phẩm bằng ảnh (Image to Image Search)
  Future<Map<String, dynamic>?> searchProductsByImage({
    required File imageFile,
    String? categoryId,
    String? userDescription,
    int topK = 10,
  }) async {
    try {
      final uri = Uri.parse('$_ragServiceUrl/api/products/search/image')
          .replace(queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (userDescription != null && userDescription.isNotEmpty) 'user_description': userDescription,
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

  /// Multi-Agent RAG query (text only) - Gọi qua C# backend
  Future<Map<String, dynamic>?> multiAgentQuery({
    required String query,
    String? userDescription,
    String? categoryId,
    int topK = 5,
    bool enableCritic = true,
    required String baseUrl,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      
      final res = await http
          .post(
            Uri.parse('$baseUrl/Chat/multi-agent-query'),
            headers: headers,
            body: jsonEncode({
              'query': query,
              'userDescription': userDescription,
              'categoryId': categoryId,
              'topK': topK,
              'enableCritic': enableCritic,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        print('Error in Multi-Agent RAG query: ${res.statusCode} - ${res.body}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Exception in Multi-Agent RAG query: $e');
      return null;
    }
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
    try {
      final headers = await ApiService().getHeaders();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/Chat/multi-agent-query-image'),
      );

      // Add image
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add form fields
      if (query != null && query.isNotEmpty) {
        request.fields['query'] = query;
      }
      if (userDescription != null && userDescription.isNotEmpty) {
        request.fields['userDescription'] = userDescription;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        request.fields['categoryId'] = categoryId;
      }
      request.fields['topK'] = topK.toString();
      request.fields['enableCritic'] = enableCritic.toString();

      // Add headers
      request.headers.addAll(headers);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error in Multi-Agent RAG query with image: ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception in Multi-Agent RAG query with image: $e');
      return null;
    }
  }

  /// Multi-Agent RAG query (text only) - Gọi trực tiếp Python service
  Future<Map<String, dynamic>?> multiAgentQueryDirect({
    required String query,
    String? userDescription,
    String? categoryId,
    int topK = 5,
    bool enableCritic = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_ragServiceUrl/api/multi-agent/query'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'query': query,
              'user_description': userDescription,
              'category_id': categoryId,
              'top_k': topK,
              'enable_critic': enableCritic,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        print('Error in Multi-Agent RAG query (direct): ${res.statusCode} - ${res.body}');
        return null;
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('Exception in Multi-Agent RAG query (direct): $e');
      return null;
    }
  }

  /// Multi-Agent RAG query với image - Gọi trực tiếp Python service
  Future<Map<String, dynamic>?> multiAgentQueryWithImageDirect({
    required File imageFile,
    String? query,
    String? userDescription,
    String? categoryId,
    int topK = 5,
    bool enableCritic = true,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ragServiceUrl/api/multi-agent/query-image'),
      );

      // Add image
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add query parameters
      if (query != null && query.isNotEmpty) {
        request.fields['query'] = query;
      }
      if (userDescription != null && userDescription.isNotEmpty) {
        request.fields['user_description'] = userDescription;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        request.fields['category_id'] = categoryId;
      }
      request.fields['top_k'] = topK.toString();
      request.fields['enable_critic'] = enableCritic.toString();

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('Error in Multi-Agent RAG query with image (direct): ${response.statusCode} - ${response.body}');
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception in Multi-Agent RAG query with image (direct): $e');
      return null;
    }
  }
}

