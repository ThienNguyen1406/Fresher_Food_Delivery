import 'dart:io';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class StatisticsApi {
  String? _lastExportedFilePath;
  
  /// Get path of last exported file
  String? get lastExportedFilePath => _lastExportedFilePath;
  
  /// Export báo cáo thống kê ra file Excel
  Future<Map<String, dynamic>> exportToExcel({
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final url = '${Constant().baseUrl}/Statistics/export-excel${queryString.isNotEmpty ? '?$queryString' : ''}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Get file name from Content-Disposition header or use default
        String fileName = 'BaoCaoThongKe_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          // Parse filename from Content-Disposition header
          // Handle both formats: filename="..." and filename*=UTF-8'...'...
          // Extract filename using simple string operations to avoid regex complexity
          String? extractedName;
          
          // Try to find filename= or filename*=
          final filenameIndex = contentDisposition.indexOf('filename=');
          if (filenameIndex != -1) {
            var startIndex = filenameIndex + 9; // length of "filename="
            
            // Skip optional encoding prefix like "UTF-8''"
            if (contentDisposition.substring(startIndex).startsWith("UTF-8''")) {
              startIndex += 7;
            }
            
            // Find the filename value
            var valueStart = startIndex;
            // Skip optional quote
            if (valueStart < contentDisposition.length && 
                (contentDisposition[valueStart] == '"' || contentDisposition[valueStart] == "'")) {
              valueStart++;
            }
            
            // Find end of filename (before semicolon, quote, or end of string)
            var valueEnd = valueStart;
            while (valueEnd < contentDisposition.length) {
              final char = contentDisposition[valueEnd];
              if (char == ';' || char == '"' || char == "'") {
                break;
              }
              valueEnd++;
            }
            
            if (valueEnd > valueStart) {
              extractedName = contentDisposition.substring(valueStart, valueEnd).trim();
            }
          }
          
          if (extractedName != null && extractedName.isNotEmpty) {
            // Remove any quotes that might be in the name
            extractedName = extractedName.replaceAll('"', '').replaceAll("'", '');
            // Take only the filename part (before any semicolon)
            extractedName = extractedName.split(';').first.trim();
            if (extractedName.isNotEmpty) {
              fileName = extractedName;
            }
          }
        }
        
        // Clean filename - remove any invalid characters
        final invalidCharsPattern = RegExp(r'[<>:"/\\|?*]');
        fileName = fileName.replaceAll(invalidCharsPattern, '_');
        if (!fileName.endsWith('.xlsx')) {
          fileName = '$fileName.xlsx';
        }
        
        // Save file to Downloads folder on mobile devices
        Directory? directory;
        try {
          if (Platform.isAndroid) {
            // Android: Try multiple methods to get Downloads folder
            // Method 1: Try using path_provider with external storage
            try {
              final externalDir = await getExternalStorageDirectory();
              if (externalDir != null) {
                // Navigate to Downloads from app's external directory
                // On Android, Downloads is usually at /storage/emulated/0/Download
                final downloadsDir = Directory('/storage/emulated/0/Download');
                if (await downloadsDir.exists()) {
                  directory = downloadsDir;
                } else {
                  // Try alternative path
                  final altDownloadsDir = Directory('/sdcard/Download');
                  if (await altDownloadsDir.exists()) {
                    directory = altDownloadsDir;
                  } else {
                    // Fallback to external storage root
                    directory = Directory(externalDir.path);
                  }
                }
              }
            } catch (e) {
              // Method 2: Direct path (most common on Android)
              try {
                final directPath = Directory('/storage/emulated/0/Download');
                if (await directPath.exists()) {
                  directory = directPath;
                } else {
                  // Try alternative path
                  final altPath = Directory('/sdcard/Download');
                  if (await altPath.exists()) {
                    directory = altPath;
                  } else {
                    throw Exception('Downloads directory not found');
                  }
                }
              } catch (e2) {
                // Last resort: use external storage directory
                final externalDir = await getExternalStorageDirectory();
                directory = externalDir ?? await getApplicationDocumentsDirectory();
              }
            }
          } else if (Platform.isIOS) {
            // iOS: Use Documents directory (iOS doesn't have public Downloads)
            directory = await getApplicationDocumentsDirectory();
          } else {
            // Other platforms: Use application documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          // Final fallback to application documents directory
          directory = await getApplicationDocumentsDirectory();
        }
        
        // Ensure directory is not null
        if (directory == null) {
          return {
            'success': false,
            'error': 'Could not determine download directory',
          };
        }
        
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        // Check if file bytes are valid
        if (response.bodyBytes.isEmpty) {
          return {
            'success': false,
            'error': 'Response body is empty. Backend may have failed to generate Excel file.',
          };
        }
        
        // Write file
        try {
          await file.writeAsBytes(response.bodyBytes);
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to write file: $e',
          };
        }
        
        // Verify file was written
        if (!await file.exists()) {
          return {
            'success': false,
            'error': 'File was not created. Please check storage permissions.',
          };
        }
        
        // Get file size
        final fileSize = await file.length();
        if (fileSize == 0) {
          return {
            'success': false,
            'error': 'File was created but is empty.',
          };
        }
        
        // Save file path
        _lastExportedFilePath = filePath;
        
        // Log the actual path where file was saved
        print('File saved to: $filePath');
        
        // Try to open file (optional - don't fail if this doesn't work)
        try {
          await OpenFile.open(filePath);
        } catch (e) {
          // File saved successfully but couldn't open - this is OK
          // User can manually open the file
          print('Could not open file: $e');
        }
        
        return {
          'success': true,
          'filePath': filePath,
          'fileName': fileName,
          'fileSize': fileSize,
        };
      } else {
        final errorBody = response.body;
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${errorBody.length > 200 ? errorBody.substring(0, 200) : errorBody}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
      };
    }
  }
}

