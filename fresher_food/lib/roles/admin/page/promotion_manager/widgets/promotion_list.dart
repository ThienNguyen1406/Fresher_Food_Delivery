import 'package:flutter/material.dart';
import 'package:fresher_food/models/Sale.dart';
import 'promotion_card.dart';

class PromotionList extends StatelessWidget {
  final List<Sale> sales;
  final VoidCallback onRefresh;
  final Function(Sale) onEdit;
  final Function(String) onDelete;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color errorColor;

  const PromotionList({
    super.key,
    required this.sales,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final sale = sales[index];
          return PromotionCard(
            sale: sale,
            onEdit: () => onEdit(sale),
            onDelete: () => onDelete(sale.idSale),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            primaryColor: primaryColor,
            errorColor: errorColor,
          );
        },
      ),
    );
  }
}

