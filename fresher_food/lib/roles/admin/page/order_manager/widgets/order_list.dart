import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'order_card.dart';

class OrderList extends StatelessWidget {
  final List<Order> orders;
  final Map<String, String> statusMap;
  final Map<String, Color> statusColorMap;
  final Function(Order) onViewDetail;
  final Function(Order) onUpdateStatus;
  final String Function(DateTime) formatDate;
  final VoidCallback onRefresh;
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textLightColor;

  const OrderList({
    super.key,
    required this.orders,
    required this.statusMap,
    required this.statusColorMap,
    required this.onViewDetail,
    required this.onUpdateStatus,
    required this.formatDate,
    required this.onRefresh,
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textLightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        backgroundColor: surfaceColor,
        color: primaryColor,
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(
              order: order,
              statusMap: statusMap,
              statusColorMap: statusColorMap,
              onViewDetail: onViewDetail,
              onUpdateStatus: onUpdateStatus,
              formatDate: formatDate,
              primaryColor: primaryColor,
              accentColor: accentColor,
              surfaceColor: surfaceColor,
              textColor: textColor,
              textLightColor: textLightColor,
            );
          },
        ),
      ),
    );
  }
}

