import 'package:flutter/material.dart';
import 'package:fresher_food/models/PasswordResetRequest.dart';
import 'password_reset_request_card.dart';

class PasswordResetRequestList extends StatelessWidget {
  final List<PasswordResetRequest> requests;
  final VoidCallback onRefresh;
  final String Function(DateTime) formatDate;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getStatusText;
  final Function(PasswordResetRequest) onTap;
  final Function(PasswordResetRequest) onApprove;
  final Function(PasswordResetRequest) onReject;

  const PasswordResetRequestList({
    super.key,
    required this.requests,
    required this.onRefresh,
    required this.formatDate,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.getStatusText,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: Colors.green.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return PasswordResetRequestCard(
            request: request,
            formatDate: formatDate,
            getStatusColor: getStatusColor,
            getStatusIcon: getStatusIcon,
            getStatusText: getStatusText,
            onTap: () => onTap(request),
            onApprove: () => onApprove(request),
            onReject: () => onReject(request),
          );
        },
      ),
    );
  }
}

