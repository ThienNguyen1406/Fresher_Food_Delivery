import 'dart:convert';

import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class OrderApi {
  // ==================== ORDER ====================
  Future<List<Order>> getOrders() async {
    final res = await http.get(Uri.parse('${Constant().baseUrl}/Orders'));
    if (res.statusCode == 200) {
      final dynamic data = jsonDecode(res.body);

      // Kiểm tra nếu data là Map và có key chứa danh sách orders
      if (data is Map<String, dynamic>) {
        // Tìm key chứa danh sách orders (có thể là 'data', 'orders', 'items', v.v.)
        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> orderList = data['data'];
          return orderList.map((e) => Order.fromJson(e)).toList();
        } else if (data.containsKey('orders') && data['orders'] is List) {
          final List<dynamic> orderList = data['orders'];
          return orderList.map((e) => Order.fromJson(e)).toList();
        } else if (data.containsKey('items') && data['items'] is List) {
          final List<dynamic> orderList = data['items'];
          return orderList.map((e) => Order.fromJson(e)).toList();
        } else {
          // Nếu không tìm thấy key nào phù hợp, thử lấy giá trị đầu tiên là List
          final dynamic firstValue = data.values.first;
          if (firstValue is List) {
            return firstValue.map((e) => Order.fromJson(e)).toList();
          } else {
            throw Exception('Cấu trúc dữ liệu không hợp lệ: $data');
          }
        }
      }
      // Nếu data là List thì xử lý bình thường
      else if (data is List) {
        return data.map((e) => Order.fromJson(e)).toList();
      } else {
        throw Exception('Định dạng dữ liệu không hợp lệ: ${data.runtimeType}');
      }
    } else {
      throw Exception('Không thể tải danh sách đơn hàng: ${res.statusCode}');
    }
  }

// Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final headers = await ApiService().getHeaders();

      final requestData = {
        'trangThai': status,
      };

      print('🔄 Updating order status: $orderId -> $status');

      final response = await http
          .put(
            Uri.parse('${Constant().baseUrl}/Orders/$orderId/status'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('📦 Update Order Status API Response: ${response.statusCode}');
      print('📦 Update Order Status API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order status updated successfully: $data');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            'Failed to update order status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      throw Exception('Error updating order status: $e');
    }
  }

  Future<bool> createOrder(Order order, List<OrderDetail> orderDetails) async {
    try {
      final headers = await ApiService().getHeaders();

      final requestData = {
        'order': order.toJson(),
        'orderDetails': orderDetails.map((detail) => detail.toJson()).toList(),
      };

      print('🛒 Creating order with data: $requestData');

      final response = await http
          .post(
            Uri.parse('${Constant().baseUrl}/Orders'),
            headers: headers,
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('📦 Create Order API Response: ${response.statusCode}');
      print('📦 Create Order API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order created successfully: $data');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            'Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }

  // Lấy danh sách đơn hàng của user
  Future<List<Order>> getOrdersByUser() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      print('Fetching orders for user: ${user.maTaiKhoan}');
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Orders/user/${user.maTaiKhoan}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Orders API Response: ${response.statusCode}');
      print('Orders API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Orders API Data: $data');

        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> ordersData = data['data'];
          print(
              'Found ${ordersData.length} orders for user: ${user.maTaiKhoan}');

          return ordersData.map((e) => Order.fromJson(e)).toList();
        } else {
          print('Unexpected response structure: $data');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('No orders found for user: ${user.maTaiKhoan}');
        return [];
      } else {
        print(
            'Failed to load orders: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting orders: $e');
      throw Exception('Error getting orders: $e');
    }
  }

  // Lấy số lượng đơn hàng bằng cách đếm từ danh sách
  Future<int> getOrderCount() async {
    try {
      final orders = await getOrdersByUser();
      return orders.length;
    } catch (e) {
      print('Error getting order count: $e');
      return 0;
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Orders/$orderId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Order Detail API Response: ${response.statusCode}');
      print('Order Detail API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Order Detail API Data: $data');

        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          return data['data']; // Trả về data chứa order và orderDetails
        } else {
          print('Unexpected order detail response structure: $data');
          throw Exception('Unexpected response structure');
        }
      } else {
        throw Exception('Failed to load order detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting order detail: $e');
      throw Exception('Error getting order detail: $e');
    }
  }

}
