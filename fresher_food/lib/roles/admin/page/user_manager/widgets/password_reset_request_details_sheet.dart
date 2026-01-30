import 'package:flutter/material.dart';
import 'package:fresher_food/models/PasswordResetRequest.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class PasswordResetRequestDetailsSheet extends StatelessWidget {
  final PasswordResetRequest request;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getStatusText;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PasswordResetRequestDetailsSheet({
    super.key,
    required this.request,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.getStatusText,
    required this.onApprove,
    required this.onReject,
  });

  static void show(
    BuildContext context, {
    required PasswordResetRequest request,
    required Color Function(String) getStatusColor,
    required IconData Function(String) getStatusIcon,
    required String Function(String) getStatusText,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PasswordResetRequestDetailsSheet(
        request: request,
        getStatusColor: getStatusColor,
        getStatusIcon: getStatusIcon,
        getStatusText: getStatusText,
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(request.trangThai);
    final statusIcon = getStatusIcon(request.trangThai);
    final statusText = getStatusText(request.trangThai);

    return Container(
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
          _DetailRow(
            label: 'Mã yêu cầu',
            value: request.maYeuCau,
            icon: Iconsax.document_text,
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Email',
            value: request.email,
            icon: Iconsax.sms,
          ),
          if (request.tenNguoiDung != null) ...[
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Tên người dùng',
              value: request.tenNguoiDung!,
              icon: Iconsax.user,
            ),
          ],
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Trạng thái',
            value: statusText,
            icon: statusIcon,
            color: statusColor,
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Ngày tạo',
            value: DateFormat('dd/MM/yyyy HH:mm').format(request.ngayTao),
            icon: Iconsax.calendar,
          ),
          if (request.ngayXuLy != null) ...[
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Ngày xử lý',
              value: DateFormat('dd/MM/yyyy HH:mm').format(request.ngayXuLy!),
              icon: Iconsax.clock,
            ),
          ],
          if (request.maAdminXuLy != null) ...[
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Admin xử lý',
              value: request.maAdminXuLy!,
              icon: Iconsax.profile_circle,
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
                      onReject();
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
                      onApprove();
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
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

