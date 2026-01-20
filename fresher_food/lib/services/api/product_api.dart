import 'dart:convert';
import 'dart:io';

import 'package:fresher_food/models/Product.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show Platform, Directory, File;

class ProductApi {
  Future<List<Product>> getProducts() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return (jsonDecode(res.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product/$id'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Failed to load product $id: ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) return Product.fromJson(data.first);
      if (data is Map<String, dynamic>) return Product.fromJson(data);

      print('Unexpected format for $id: ${data.runtimeType}');
      return null;
    } catch (e) {
      print('Error fetching $id: $e');
      return null;
    }
  }

  //search products by name
  Future<List<Product>> searchProducts(String name) async {
    final response = await http
        .get(Uri.parse('${Constant().baseUrl}/Product/Search?name=$name'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Không tìm thấy sản phẩm');
    }
  }

// Trong ApiService class
  Future<bool> addProduct(Product product, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${Constant().baseUrl}/Product'));

      // Thêm các trường dữ liệu
      request.fields['TenSanPham'] = product.tenSanPham;
      request.fields['MoTa'] = product.moTa;
      request.fields['GiaBan'] = product.giaBan.toString();
      request.fields['SoLuongTon'] = product.soLuongTon.toString();
      request.fields['XuatXu'] = product.xuatXu;
      request.fields['DonViTinh'] = product.donViTinh;
      request.fields['MaDanhMuc'] = product.maDanhMuc;
      
      // Thêm ngày sản xuất và hạn sử dụng
      if (product.ngaySanXuat != null) {
        request.fields['NgaySanXuat'] = product.ngaySanXuat!.toIso8601String();
      }
      if (product.ngayHetHan != null) {
        request.fields['NgayHetHan'] = product.ngayHetHan!.toIso8601String();
      }

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('Anh', imageFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Thêm sản phẩm thành công';
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi thêm sản phẩm: $e');
    }
  }

  Future<bool> updateProduct(
      String id, Product product, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'PUT', Uri.parse('${Constant().baseUrl}/Product/$id'));

      // Thêm các trường dữ liệu
      request.fields['TenSanPham'] = product.tenSanPham;
      request.fields['MoTa'] = product.moTa;
      request.fields['GiaBan'] = product.giaBan.toString();
      request.fields['SoLuongTon'] = product.soLuongTon.toString();
      request.fields['XuatXu'] = product.xuatXu;
      request.fields['DonViTinh'] = product.donViTinh;
      request.fields['MaDanhMuc'] = product.maDanhMuc;
      
      // Thêm ngày sản xuất và hạn sử dụng
      if (product.ngaySanXuat != null) {
        request.fields['NgaySanXuat'] = product.ngaySanXuat!.toIso8601String();
      }
      if (product.ngayHetHan != null) {
        request.fields['NgayHetHan'] = product.ngayHetHan!.toIso8601String();
      }

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('Anh', imageFile.path));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['message'] == 'Cập nhật sản phẩm thành công';
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi cập nhật sản phẩm: $e');
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Delete Product API Response: ${response.statusCode}');
      print('Delete Product API Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map && jsonResponse['message'] != null) {
            // Chấp nhận cả "Xóa sản phẩm thành công" và "Đã chuyển sản phẩm vào thùng rác"
            return jsonResponse['message'].toString().contains('thành công') ||
                   jsonResponse['message'].toString().contains('thùng rác');
          }
        } catch (e) {
          // Nếu không parse được JSON, kiểm tra string
          return response.body.contains('thành công') || response.body.contains('thùng rác');
        }
        return true;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Không thể xóa sản phẩm');
        } catch (e) {
          throw Exception('Không thể xóa sản phẩm: ${response.body}');
        }
      } else {
        throw Exception('Failed to delete product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Lỗi xóa sản phẩm: $e');
    }
  }

  // Lấy danh sách sản phẩm trong thùng rác
  Future<List<Map<String, dynamic>>> getTrashProducts() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product/Trash'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load trash products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting trash products: $e');
      throw Exception('Lỗi lấy danh sách thùng rác: $e');
    }
  }

  // Khôi phục sản phẩm từ thùng rác
  Future<bool> restoreProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.post(
        Uri.parse('${Constant().baseUrl}/Product/$id/Restore'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Khôi phục sản phẩm thành công';
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không tìm thấy sản phẩm trong thùng rác');
      } else {
        throw Exception('Failed to restore product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error restoring product: $e');
      throw Exception('Lỗi khôi phục sản phẩm: $e');
    }
  }

  // Xóa vĩnh viễn sản phẩm từ thùng rác
  Future<bool> permanentDeleteProduct(String id) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id/Permanent'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Đã xóa vĩnh viễn sản phẩm';
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể xóa vĩnh viễn sản phẩm');
      } else {
        throw Exception('Failed to permanent delete product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error permanent deleting product: $e');
      throw Exception('Lỗi xóa vĩnh viễn sản phẩm: $e');
    }
  }

  /// Xuất danh sách sản phẩm ra file Excel
  Future<Map<String, dynamic>> exportToExcel() async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.get(
        Uri.parse('${Constant().baseUrl}/Product/export-excel'),
        headers: headers,
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Lấy tên file từ header hoặc tạo tên mặc định
        String fileName = 'DanhSachSanPham_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          // Parse filename từ Content-Disposition header
          final filenameIndex = contentDisposition.indexOf('filename=');
          if (filenameIndex != -1) {
            var startIndex = filenameIndex + 9; // length of "filename="
            
            // Skip optional encoding prefix
            if (contentDisposition.substring(startIndex).startsWith("UTF-8''")) {
              startIndex += 7;
            }
            
            var valueStart = startIndex;
            if (valueStart < contentDisposition.length && 
                (contentDisposition[valueStart] == '"' || contentDisposition[valueStart] == "'")) {
              valueStart++;
            }
            
            var valueEnd = valueStart;
            while (valueEnd < contentDisposition.length) {
              final char = contentDisposition[valueEnd];
              if (char == ';' || char == '"' || char == "'") {
                break;
              }
              valueEnd++;
            }
            
            if (valueEnd > valueStart) {
              fileName = contentDisposition.substring(valueStart, valueEnd).trim();
              fileName = fileName.replaceAll('"', '').replaceAll("'", '');
            }
          }
        }
        
        // Clean filename - remove invalid characters
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
            try {
              // Method 1: Try public Downloads directory
              final downloadsDir = Directory('/storage/emulated/0/Download');
              if (await downloadsDir.exists() || await downloadsDir.parent.exists()) {
                // Create if doesn't exist
                if (!await downloadsDir.exists()) {
                  await downloadsDir.create(recursive: true);
                }
                directory = downloadsDir;
              } else {
                // Method 2: Try alternative path
                final altDownloadsDir = Directory('/sdcard/Download');
                if (await altDownloadsDir.exists() || await altDownloadsDir.parent.exists()) {
                  if (!await altDownloadsDir.exists()) {
                    await altDownloadsDir.create(recursive: true);
                  }
                  directory = altDownloadsDir;
                } else {
                  // Method 3: Use external storage directory and create Download subfolder
                  final externalDir = await getExternalStorageDirectory();
                  if (externalDir != null) {
                    // Try to use Downloads from external storage
                    final appDownloadsDir = Directory('${externalDir.path}/Download');
                    if (!await appDownloadsDir.exists()) {
                      await appDownloadsDir.create(recursive: true);
                    }
                    directory = appDownloadsDir;
                  } else {
                    throw Exception('Cannot access external storage');
                  }
                }
              }
            } catch (e) {
              print('Error accessing Downloads: $e');
              // Fallback: use external storage directory
              try {
                final externalDir = await getExternalStorageDirectory();
                if (externalDir != null) {
                  // Create Download folder in app's external directory
                  final appDownloadsDir = Directory('${externalDir.path}/Download');
                  if (!await appDownloadsDir.exists()) {
                    await appDownloadsDir.create(recursive: true);
                  }
                  directory = appDownloadsDir;
                } else {
                  directory = await getApplicationDocumentsDirectory();
                }
              } catch (e2) {
                // Final fallback
                directory = await getApplicationDocumentsDirectory();
              }
            }
          } else if (Platform.isIOS) {
            // iOS: Use Documents directory
            directory = await getApplicationDocumentsDirectory();
          } else {
            // Other platforms: Try Downloads first, then Documents
            directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          print('Error determining directory: $e');
          // Final fallback to application documents directory
          directory = await getApplicationDocumentsDirectory();
        }
        
        // Directory is guaranteed to be non-null at this point
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        // Check if file bytes are valid
        if (response.bodyBytes.isEmpty) {
          return {
            'success': false,
            'error': 'File Excel rỗng. Backend có thể đã lỗi khi tạo file.',
          };
        }
        
        // Write file
        try {
          await file.writeAsBytes(response.bodyBytes);
        } catch (e) {
          return {
            'success': false,
            'error': 'Lỗi khi ghi file: $e',
          };
        }
        
        // Verify file was written
        if (!await file.exists()) {
          return {
            'success': false,
            'error': 'File không được tạo. Vui lòng kiểm tra quyền truy cập bộ nhớ.',
          };
        }
        
        // Get file size
        final fileSize = await file.length();
        if (fileSize == 0) {
          return {
            'success': false,
            'error': 'File được tạo nhưng rỗng.',
          };
        }
        
        // Try to open file
        try {
          await OpenFile.open(filePath);
        } catch (e) {
          // File saved successfully but couldn't open - this is OK
          print('File đã lưu nhưng không thể mở tự động: $e');
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
        'error': 'Lỗi xuất file Excel: $e',
      };
    }
  }
}
