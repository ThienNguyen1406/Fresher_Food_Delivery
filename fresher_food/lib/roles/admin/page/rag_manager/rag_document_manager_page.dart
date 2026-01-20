import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fresher_food/services/api/rag_api.dart';
import 'package:fresher_food/roles/admin/page/rag_manager/admin_rag_conversation_list_page.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

/// Màn hình quản lý RAG Documents cho Admin
/// Admin có thể upload file dữ liệu, xem danh sách, xóa documents và query RAG
class RagDocumentManagerPage extends StatefulWidget {
  const RagDocumentManagerPage({super.key});

  @override
  State<RagDocumentManagerPage> createState() => _RagDocumentManagerPageState();
}

class _RagDocumentManagerPageState extends State<RagDocumentManagerPage>
    with SingleTickerProviderStateMixin {
  final RagApi _ragApi = RagApi();
  List<dynamic> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  String? _successMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load danh sách documents
  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documents = await _ragApi.getDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách documents: $e';
        _isLoading = false;
      });
    }
  }

  /// Upload file document
  Future<void> _uploadDocument() async {
    try {
      // Chọn file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx', 'pdf', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);

      setState(() {
        _isUploading = true;
        _error = null;
        _successMessage = null;
      });

      // Upload file
      final response = await _ragApi.uploadDocument(file);

      if (response != null) {
        setState(() {
          _successMessage =
              'Upload thành công! File "${response['file_name']}" đã được xử lý thành ${response['total_chunks']} chunks.';
          _isUploading = false;
        });

        // Reload danh sách
        await _loadDocuments();

        // Clear success message sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _error = 'Upload thất bại. Vui lòng thử lại.';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi upload file: $e';
        _isUploading = false;
      });
    }
  }

  /// Xóa document
  Future<void> _deleteDocument(String fileId, String fileName) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa file "$fileName"?\n\nTất cả các chunks vector của file này sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _ragApi.deleteDocument(fileId);

      if (success) {
        setState(() {
          _successMessage = 'Đã xóa file "$fileName" thành công.';
        });

        // Reload danh sách
        await _loadDocuments();

        // Clear success message sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _error = 'Xóa file thất bại. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi xóa file: $e';
        _isLoading = false;
      });
    }
  }

  /// Format date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// Get file type icon
  IconData _getFileTypeIcon(String? fileType) {
    if (fileType == null) return Iconsax.document;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Iconsax.document_text;
      case 'docx':
        return Iconsax.document;
      case 'txt':
        return Iconsax.document_text_1;
      case 'xlsx':
        return Iconsax.document_download;
      default:
        return Iconsax.document;
    }
  }

  /// Get file type color
  Color _getFileTypeColor(String? fileType) {
    if (fileType == null) return Colors.grey;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.green;
      case 'xlsx':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: const [
                Tab(
                  icon: Icon(Iconsax.document_text),
                  text: 'Quản lý tài nguyên',
                ),
                Tab(
                  icon: Icon(Iconsax.message_text),
                  text: 'Tìm kiếm thông tin',
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsTab(),
                const AdminRagConversationListPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      children: [
        // Success/Error messages
        if (_successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _successMessage = null),
                  color: Colors.green.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _error = null),
                  color: Colors.red.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Upload button
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadDocument,
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.document_upload),
            label: Text(_isUploading ? 'Đang upload...' : 'Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Info card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hỗ trợ các file có đuôi .txt, .pdf, .xlst, docx',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI sẽ hỗ trợ bạn đọc và bóc tách dữ liệu, bạn có thể hỏi thông tin liên quan tại "Tìm Kiếm Thông Tin" ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Documents list
        Expanded(
          child: _isLoading && _documents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.document_text,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có document nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload file để bắt đầu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          final fileId = doc['file_id'] ?? '';
                          final fileName = doc['file_name'] ?? 'Unknown';
                          final fileType = doc['file_type'] ?? '';
                          final totalChunks = doc['total_chunks'] ?? 0;
                          final uploadDate = doc['upload_date'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getFileTypeColor(fileType)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getFileTypeIcon(fileType),
                                  color: _getFileTypeColor(fileType),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.document_text,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalChunks chunks',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Iconsax.calendar,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(uploadDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Iconsax.trash,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteDocument(fileId, fileName),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
