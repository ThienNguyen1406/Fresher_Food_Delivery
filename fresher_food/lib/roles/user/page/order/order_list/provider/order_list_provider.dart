// providers/orderlist_provider.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_list/provider/order_list_service.dart';
import 'package:fresher_food/roles/user/page/order/order_list/provider/order_list_state.dart';


class OrderListProvider with ChangeNotifier {
  final OrderListService _orderListService = OrderListService();
  OrderListState _state = const OrderListState();

  // Getters
  OrderListState get state => _state;
  List<Order> get orders => _state.orders;
  bool get isLoading => _state.isLoading;
  String get errorMessage => _state.errorMessage;

  // Methods
  Future<void> loadOrders() async {
    _updateState(_state.loading());
    
    try {
      final orders = await _orderListService.getOrdersByUser();
      _updateState(_state.success(orders));
    } catch (e) {
      _updateState(_state.error(e.toString()));
    }
  }

  void retryLoading() {
    loadOrders();
  }

  void clearError() {
    _updateState(_state.clearError());
  }

  // Private method
  void _updateState(OrderListState newState) {
    _state = newState;
    notifyListeners();
  }

  // Helper methods
  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'confirmed':
        return const Color(0xFF42A5F5);
      case 'shipping':
        return const Color(0xFF7E57C2);
      case 'delivered':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF78909C);
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'shipping':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day} Th${date.month}, ${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}