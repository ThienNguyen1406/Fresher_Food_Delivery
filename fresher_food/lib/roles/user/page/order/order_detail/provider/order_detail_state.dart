// state/orderdetail_state.dart
import 'package:fresher_food/models/Order.dart';

class OrderDetailState {
  final Order? order;
  final List<OrderDetail> orderDetails;
  final bool isLoading;
  final String errorMessage;
  final double totalAmount;

  const OrderDetailState({
    this.order,
    this.orderDetails = const [],
    this.isLoading = true,
    this.errorMessage = '',
    this.totalAmount = 0.0,
  });

  OrderDetailState copyWith({
    Order? order,
    List<OrderDetail>? orderDetails,
    bool? isLoading,
    String? errorMessage,
    double? totalAmount,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      orderDetails: orderDetails ?? this.orderDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  OrderDetailState loading() {
    return copyWith(
      isLoading: true,
      errorMessage: '',
    );
  }

  OrderDetailState success({
    required Order order,
    required List<OrderDetail> orderDetails,
    required double totalAmount,
  }) {
    return copyWith(
      order: order,
      orderDetails: orderDetails,
      totalAmount: totalAmount,
      isLoading: false,
      errorMessage: '',
    );
  }

  OrderDetailState error(String errorMessage) {
    return copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    );
  }

  OrderDetailState clearError() {
    return copyWith(errorMessage: '');
  }
}
