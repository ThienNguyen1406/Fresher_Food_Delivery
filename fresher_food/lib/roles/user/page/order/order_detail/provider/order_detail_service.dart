// services/orderdetail_service.dart
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/services/api/order_api.dart';

class OrderDetailService {
  final OrderApi _orderApi = OrderApi();

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final data = await _orderApi.getOrderDetail(orderId);
      final order = Order.fromJson(data['order']);
      final orderDetails = (data['orderDetails'] as List)
          .map((e) => OrderDetail.fromJson(e))
          .toList();

      final totalAmount = _calculateTotalAmount(orderDetails);

      return {
        'order': order,
        'orderDetails': orderDetails,
        'totalAmount': totalAmount,
        'error': null,
      };
    } catch (e) {
      return {
        'order': null,
        'orderDetails': [],
        'totalAmount': 0.0,
        'error': 'Lỗi khi tải chi tiết đơn hàng: $e',
      };
    }
  }

  double _calculateTotalAmount(List<OrderDetail> orderDetails) {
    double total = 0.0;
    for (var detail in orderDetails) {
      total += detail.giaBan * detail.soLuong;
    }
    return total;
  }
}
