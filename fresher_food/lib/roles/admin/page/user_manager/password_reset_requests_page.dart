import 'package:flutter/material.dart';
import 'package:fresher_food/models/PasswordResetRequest.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình quản lý yêu cầu đặt lại mật khẩu cho Admin
class PasswordResetRequestsPage extends StatefulWidget {
  const PasswordResetRequestsPage({super.key});

  @override
  State<PasswordResetRequestsPage> createState() => _PasswordResetRequestsPageState();
}

class _PasswordResetRequestsPageState extends State<PasswordResetRequestsPage> {
  final UserApi _userApi = UserApi();
  List<PasswordResetRequest> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All'; // All, Pending, Approved, Rejected
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
    _loadRequests();
  }

  Future<void> _loadCurrentAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentAdminId = prefs.getString('maTaiKhoan');
    });
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trangThai = _selectedFilter == 'All' ? null : _selectedFilter;
      final requests = await _userApi.getPasswordResetRequests(trangThai: trangThai);
      
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processRequest(PasswordResetRequest request, String action) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'Approve' ? 'Xác nhận duyệt' : 'Xác nhận từ chối'),
        content: Text(
          action == 'Approve'
              ? 'Bạn có chắc chắn muốn duyệt yêu cầu đặt lại mật khẩu cho ${request.email}?'
              : 'Bạn có chắc chắn muốn từ chối yêu cầu đặt lại mật khẩu cho ${request.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: action == 'Approve' ? Colors.green : Colors.red,
            ),
            child: Text(action == 'Approve' ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final result = await _userApi.processPasswordReset(
        maYeuCau: request.maYeuCau,
        action: action,
        maAdmin: _currentAdminId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Xử lý thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRequests(); // Reload list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  Color _getStatusColor(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return Iconsax.clock;
      case 'Approved':
        return Iconsax.tick_circle;
      case 'Rejected':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  String _getStatusText(String trangThai) {
    switch (trangThai) {
      case 'Pending':
        return 'Chờ xử lý';
      case 'Approved':
        return 'Đã duyệt';
      case 'Rejected':
        return 'Đã từ chối';
      default:
        return trangThai;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests.where((r) => r.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Yêu cầu đặt lại mật khẩu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pendingCount > 99 ? '99+' : '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadRequests,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'Chờ xử lý'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'Đã duyệt'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', 'Đã từ chối'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.danger,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadRequests,
                              icon: const Icon(Iconsax.refresh),
                              label: const Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade100,
                                        Colors.grey.shade200,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Iconsax.document_text,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Chưa có yêu cầu nào',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilter == 'All'
                                      ? 'Tất cả các yêu cầu sẽ hiển thị ở đây'
                                      : 'Không có yêu cầu ${_getStatusText(_selectedFilter).toLowerCase()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRequests,
                            color: Colors.green.shade600,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                final request = _requests[index];
                                return _buildRequestCard(request);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _loadRequests();
        }
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildRequestCard(PasswordResetRequest request) {
    final statusColor = _getStatusColor(request.trangThai);
    final statusIcon = _getStatusIcon(request.trangThai);
    final statusText = _getStatusText(request.trangThai);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: request.isPending ? Colors.orange.shade200 : Colors.grey.shade200,
          width: request.isPending ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Time
                  Text(
                    _formatDate(request.ngayTao),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Email
              Row(
                children: [
                  Icon(
                    Iconsax.sms,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.email,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.tenNguoiDung != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Iconsax.user,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.tenNguoiDung!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Request code
              Row(
                children: [
                  Icon(
                    Iconsax.document_text,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mã yêu cầu: ${request.maYeuCau}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              // Action buttons (only for pending requests)
              if (request.isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _processRequest(request, 'Reject'),
                        icon: const Icon(Iconsax.close_circle, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processRequest(request, 'Approve'),
                        icon: const Icon(Iconsax.tick_circle, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(PasswordResetRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'Chi tiết yêu cầu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Details
            _buildDetailRow('Mã yêu cầu', request.maYeuCau, Iconsax.document_text),
            const SizedBox(height: 16),
            _buildDetailRow('Email', request.email, Iconsax.sms),
            if (request.tenNguoiDung != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Tên người dùng', request.tenNguoiDung!, Iconsax.user),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(
              'Trạng thái',
              _getStatusText(request.trangThai),
              _getStatusIcon(request.trangThai),
              color: _getStatusColor(request.trangThai),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Ngày tạo',
              DateFormat('dd/MM/yyyy HH:mm').format(request.ngayTao),
              Iconsax.calendar,
            ),
            if (request.ngayXuLy != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Ngày xử lý',
                DateFormat('dd/MM/yyyy HH:mm').format(request.ngayXuLy!),
                Iconsax.clock,
              ),
            ],
            if (request.maAdminXuLy != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Admin xử lý',
                request.maAdminXuLy!,
                Iconsax.profile_circle,
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons (only for pending)
            if (request.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _processRequest(request, 'Reject');
                      },
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _processRequest(request, 'Approve');
                      },
                      icon: const Icon(Iconsax.tick_circle, size: 20),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

