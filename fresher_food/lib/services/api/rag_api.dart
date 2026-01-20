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
}

