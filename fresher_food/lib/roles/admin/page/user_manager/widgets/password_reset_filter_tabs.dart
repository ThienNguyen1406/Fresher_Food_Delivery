import 'package:flutter/material.dart';

class PasswordResetFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const PasswordResetFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _FilterChip(
              value: 'All',
              label: 'Tất cả',
              isSelected: selectedFilter == 'All',
              onSelected: () => onFilterChanged('All'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              value: 'Pending',
              label: 'Chờ xử lý',
              isSelected: selectedFilter == 'Pending',
              onSelected: () => onFilterChanged('Pending'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              value: 'Approved',
              label: 'Đã duyệt',
              isSelected: selectedFilter == 'Approved',
              onSelected: () => onFilterChanged('Approved'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              value: 'Rejected',
              label: 'Đã từ chối',
              isSelected: selectedFilter == 'Rejected',
              onSelected: () => onFilterChanged('Rejected'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

