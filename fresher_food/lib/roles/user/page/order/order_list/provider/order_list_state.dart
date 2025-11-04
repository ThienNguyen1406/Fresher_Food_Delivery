// state/orderlist_state.dart
import 'package:fresher_food/models/Order.dart';

class OrderListState {
  final List<Order> orders;
  final bool isLoading;
  final String errorMessage;

  const OrderListState({
    this.orders = const [],
    this.isLoading = true,
    this.errorMessage = '',
  });

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  OrderListState loading() {
    return copyWith(
      isLoading: true,
      errorMessage: '',
    );
  }

  OrderListState success(List<Order> orders) {
    return copyWith(
      orders: orders,
      isLoading: false,
      errorMessage: '',
    );
  }

  OrderListState error(String errorMessage) {
    return copyWith(
      errorMessage: errorMessage,
      isLoading: false,
    );
  }

  OrderListState clearError() {
    return copyWith(errorMessage: '');
  }
}