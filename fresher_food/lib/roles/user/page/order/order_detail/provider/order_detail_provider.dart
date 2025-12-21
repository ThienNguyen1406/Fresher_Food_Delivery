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
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('pending') || lowerStatus.contains('chờ')) {
      return 'Chờ xác nhận';
    } else if (lowerStatus.contains('confirmed') || lowerStatus.contains('đã xác nhận')) {
      return 'Đã xác nhận';
    } else if (lowerStatus.contains('shipping') || lowerStatus.contains('đang giao')) {
      return 'Đang giao hàng';
    } else if (lowerStatus.contains('delivered') || 
               lowerStatus.contains('đã giao') ||
               lowerStatus.contains('hoàn thành') ||
               lowerStatus.contains('complete')) {
      return 'Đã giao hàng';
    } else if (lowerStatus.contains('cancelled') || lowerStatus.contains('đã hủy')) {
      return 'Đã hủy';
    }
    return status;
  }

  Color getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('pending') || lowerStatus.contains('chờ')) {
      return const Color(0xFFFFA726);
    } else if (lowerStatus.contains('confirmed') || lowerStatus.contains('đã xác nhận')) {
      return const Color(0xFF42A5F5);
    } else if (lowerStatus.contains('shipping') || lowerStatus.contains('đang giao')) {
      return const Color(0xFF7E57C2);
    } else if (lowerStatus.contains('delivered') || 
               lowerStatus.contains('đã giao') ||
               lowerStatus.contains('hoàn thành') ||
               lowerStatus.contains('complete')) {
      return const Color(0xFF66BB6A);
    } else if (lowerStatus.contains('cancelled') || lowerStatus.contains('đã hủy')) {
      return const Color(0xFFEF5350);
    }
    return const Color(0xFF78909C);
  }

  IconData getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('pending') || lowerStatus.contains('chờ')) {
      return Icons.access_time_rounded;
    } else if (lowerStatus.contains('confirmed') || lowerStatus.contains('đã xác nhận')) {
      return Icons.check_circle_outline_rounded;
    } else if (lowerStatus.contains('shipping') || lowerStatus.contains('đang giao')) {
      return Icons.local_shipping_rounded;
    } else if (lowerStatus.contains('delivered') || 
               lowerStatus.contains('đã giao') ||
               lowerStatus.contains('hoàn thành') ||
               lowerStatus.contains('complete')) {
      return Icons.verified_rounded;
    } else if (lowerStatus.contains('cancelled') || lowerStatus.contains('đã hủy')) {
      return Icons.cancel_rounded;
    }
    return Icons.shopping_bag_rounded;
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

  // Kiểm tra xem đơn hàng có thể hủy không
  bool canCancelOrder() {
    if (order == null) return false;
    final status = order!.trangThai.toLowerCase();
    // Chỉ cho phép hủy khi: pending, chờ xác nhận, hoặc các status chưa được xác nhận
    return status.contains('pending') ||
           status.contains('chờ') ||
           status.contains('waiting') ||
           (!status.contains('confirmed') &&
            !status.contains('đã xác nhận') &&
            !status.contains('shipping') &&
            !status.contains('đang giao') &&
            !status.contains('delivered') &&
            !status.contains('đã giao') &&
            !status.contains('hoàn thành') &&
            !status.contains('complete') &&
            !status.contains('cancelled') &&
            !status.contains('đã hủy'));
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder() async {
    if (order == null) return false;
    
    try {
      _updateState(_state.loading());
      final orderApi = OrderDetailService();
      final success = await orderApi.cancelOrder(order!.maDonHang);
      
      if (success) {
        // Reload order detail để cập nhật status
        await loadOrderDetail(order!.maDonHang);
        return true;
      }
      return false;
    } catch (e) {
      _updateState(_state.error(e.toString()));
      return false;
    }
  }

  // Lấy danh sách các bước tracking
  List<Map<String, dynamic>> getTrackingSteps() {
    if (order == null) return [];
    
    final status = order!.trangThai.toLowerCase();
    final steps = [
      {
        'title': 'Đặt hàng',
        'status': 'completed',
        'icon': Icons.shopping_cart_rounded,
      },
      {
        'title': 'Xác nhận',
        'status': status.contains('confirmed') || 
                  status.contains('đã xác nhận') ||
                  status.contains('shipping') ||
                  status.contains('đang giao') ||
                  status.contains('delivered') ||
                  status.contains('đã giao') ||
                  status.contains('hoàn thành') ||
                  status.contains('complete')
                  ? 'completed'
                  : status.contains('pending') || status.contains('chờ')
                  ? 'current'
                  : 'pending',
        'icon': Icons.check_circle_outline_rounded,
      },
      {
        'title': 'Đang giao hàng',
        'status': status.contains('shipping') || 
                  status.contains('đang giao')
                  ? 'current'
                  : status.contains('delivered') ||
                    status.contains('đã giao') ||
                    status.contains('hoàn thành') ||
                    status.contains('complete')
                  ? 'completed'
                  : 'pending',
        'icon': Icons.local_shipping_rounded,
      },
      {
        'title': 'Hoàn thành',
        'status': status.contains('delivered') ||
                  status.contains('đã giao') ||
                  status.contains('hoàn thành') ||
                  status.contains('complete')
                  ? 'completed'
                  : 'pending',
        'icon': Icons.verified_rounded,
      },
    ];

    // Nếu đã hủy, thêm bước hủy
    if (status.contains('cancelled') || status.contains('đã hủy')) {
      steps.add({
        'title': 'Đã hủy',
        'status': 'cancelled',
        'icon': Icons.cancel_rounded,
      });
    }

    return steps;
  }
}