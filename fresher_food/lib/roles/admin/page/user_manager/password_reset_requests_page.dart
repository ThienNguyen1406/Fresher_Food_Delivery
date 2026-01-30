import 'package:flutter/material.dart';
import 'package:fresher_food/models/PasswordResetRequest.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/password_reset_app_bar.dart';
import 'widgets/password_reset_filter_tabs.dart';
import 'widgets/password_reset_loading_indicator.dart';
import 'widgets/password_reset_error_state.dart';
import 'widgets/password_reset_empty_state.dart';
import 'widgets/password_reset_request_list.dart';
import 'widgets/password_reset_confirm_dialog.dart';
import 'widgets/password_reset_request_details_sheet.dart';
import 'utils/password_reset_utils.dart';

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
    final confirm = await PasswordResetConfirmDialog.show(
      context,
      action: action,
      email: request.email,
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


  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests.where((r) => r.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: PasswordResetAppBar(
        pendingCount: pendingCount,
        onRefresh: _loadRequests,
      ),
      body: Column(
        children: [
          // Filter tabs
          PasswordResetFilterTabs(
            selectedFilter: _selectedFilter,
            onFilterChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _loadRequests();
            },
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const PasswordResetLoadingIndicator()
                : _error != null
                    ? PasswordResetErrorState(
                        error: _error!,
                        onRetry: _loadRequests,
                      )
                    : _requests.isEmpty
                        ? PasswordResetEmptyState(
                            selectedFilter: _selectedFilter,
                            getStatusText: PasswordResetUtils.getStatusText,
                          )
                        : PasswordResetRequestList(
                            requests: _requests,
                            onRefresh: _loadRequests,
                            formatDate: PasswordResetUtils.formatDate,
                            getStatusColor: PasswordResetUtils.getStatusColor,
                            getStatusIcon: PasswordResetUtils.getStatusIcon,
                            getStatusText: PasswordResetUtils.getStatusText,
                            onTap: _showRequestDetails,
                            onApprove: (request) => _processRequest(request, 'Approve'),
                            onReject: (request) => _processRequest(request, 'Reject'),
                          ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(PasswordResetRequest request) {
    PasswordResetRequestDetailsSheet.show(
      context,
      request: request,
      getStatusColor: PasswordResetUtils.getStatusColor,
      getStatusIcon: PasswordResetUtils.getStatusIcon,
      getStatusText: PasswordResetUtils.getStatusText,
      onApprove: () => _processRequest(request, 'Approve'),
      onReject: () => _processRequest(request, 'Reject'),
    );
  }
}

