import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class StatisticsHeader extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onExport;

  const StatisticsHeader({
    super.key,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Thống Kê",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tổng quan hiệu suất kinh doanh",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        // Export Excel button
        isExporting
            ? const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                onPressed: onExport,
                icon: const Icon(Iconsax.document_download),
                tooltip: 'Xuất báo cáo Excel',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
      ],
    );
  }
}

