// providers/orderdetail_provider.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/provider/order_detail_service.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/provider/order_detail_state.dart';

class OrderDetailProvider with ChangeNotifier {
  final OrderDetailService _orderDetailService = OrderDetailService();
  OrderDetailState _state = const OrderDetailState();

  // Getters
  OrderDetailState get state => _state;
  Order? get order => _state.order;
  List<OrderDetail> get orderDetails => _state.orderDetails;
  bool get isLoading => _state.isLoading;
  String get errorMessage => _state.errorMessage;
  double get totalAmount => _state.totalAmount;

  // Methods
  Future<void> loadOrderDetail(String orderId) async {
    _updateState(_state.loading());
    
    final result = await _orderDetailService.getOrderDetail(orderId);
    
    if (result['error'] != null) {
      _updateState(_state.error(result['error']));
    } else {
      _updateState(_state.success(
        order: result['order'],
        orderDetails: result['orderDetails'],
        totalAmount: result['totalAmount'],
      ));
    }
  }

  void retryLoading(String orderId) {
    loadOrderDetail(orderId);
  }

  void clearError() {
    _updateState(_state.clearError());
  }

  // Private method
  void _updateState(OrderDetailState newState) {
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

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  String formatDate(DateTime date) {
    return '${date.day} Th${date.month}, ${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}