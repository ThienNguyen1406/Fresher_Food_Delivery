import 'dart:convert';

import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/services/api/user_api.dart';
import 'package:fresher_food/services/api_service.dart';
import 'package:fresher_food/utils/constant.dart';
import 'package:http/http.dart' as http;

class OrderApi {
  // ==================== ORDER ====================
  Future<List<Order>> getOrders() async {
    try {
      print('📦 Fetching all orders from API...');
      final res = await http
          .get(Uri.parse('${Constant().baseUrl}/Orders'))
          .timeout(const Duration(seconds: 30));

      print('📦 Orders API Response: ${res.statusCode}');
      print('📦 Orders API Body: ${res.body}');

      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);

        // Kiểm tra nếu data là Map và có key chứa danh sách orders
        if (data is Map<String, dynamic>) {
          // Tìm key chứa danh sách orders (có thể là 'data', 'orders', 'items', v.v.)
          if (data.containsKey('data') && data['data'] is List) {
            final List<dynamic> orderList = data['data'];
            print('✅ Found ${orderList.length} orders in data key');
            return orderList.map((e) => Order.fromJson(e)).toList();
          } else if (data.containsKey('orders') && data['orders'] is List) {
            final List<dynamic> orderList = data['orders'];
            print('✅ Found ${orderList.length} orders in orders key');
            return orderList.map((e) => Order.fromJson(e)).toList();
          } else if (data.containsKey('items') && data['items'] is List) {
            final List<dynamic> orderList = data['items'];
            print('✅ Found ${orderList.length} orders in items key');
            return orderList.map((e) => Order.fromJson(e)).toList();
          } else {
            // Nếu không tìm thấy key nào phù hợp, thử lấy giá trị đầu tiên là List
            if (data.isNotEmpty) {
              final dynamic firstValue = data.values.first;
              if (firstValue is List) {
                print('✅ Found ${firstValue.length} orders in first value');
                return firstValue.map((e) => Order.fromJson(e)).toList();
              }
            }
            throw Exception('Cấu trúc dữ liệu không hợp lệ: $data');
          }
        }
        // Nếu data là List thì xử lý bình thường
        else if (data is List) {
          print('✅ Found ${data.length} orders in list format');
          return data.map((e) => Order.fromJson(e)).toList();
        } else {
          throw Exception(
              'Định dạng dữ liệu không hợp lệ: ${data.runtimeType}');
        }
      } else {
        throw Exception(
            'Không thể tải danh sách đơn hàng: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Error getting orders: $e');
      throw Exception('Lỗi tải danh sách đơn hàng: $e');
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

  // Lấy thống kê doanh thu theo khoảng thời gian
  Future<Map<String, dynamic>> getRevenueStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 Fetching revenue statistics...');

      // Xây dựng URL với query parameters
      final uri =
          Uri.parse('${Constant().baseUrl}/Orders/revenue/statistics').replace(
        queryParameters: {
          if (startDate != null)
            'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'endDate': endDate.toIso8601String().split('T')[0],
        },
      );

      print('📊 Revenue Statistics URL: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      print('📊 Revenue Statistics API Response: ${response.statusCode}');
      print('📊 Revenue Statistics API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Revenue Statistics Data: $data');

        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        } else {
          print('Unexpected revenue statistics response structure: $data');
          throw Exception('Unexpected response structure');
        }
      } else {
        throw Exception(
            'Failed to load revenue statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting revenue statistics: $e');
      throw Exception('Error getting revenue statistics: $e');
    }
  }

  // Lấy phân bố trạng thái đơn hàng (cho pie chart)
  Future<List<Map<String, dynamic>>> getOrderStatusDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final uri = Uri.parse('${Constant().baseUrl}/Orders/status-distribution').replace(
        queryParameters: {
          if (startDate != null)
            'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'endDate': endDate.toIso8601String().split('T')[0],
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Unexpected response structure');
      } else {
        throw Exception('Failed to load status distribution: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting status distribution: $e');
      throw Exception('Error getting status distribution: $e');
    }
  }

  // Lấy tăng trưởng đơn hàng theo tháng (cho line chart)
  Future<List<Map<String, dynamic>>> getMonthlyOrderGrowth({int? year}) async {
    try {
      final uri = Uri.parse('${Constant().baseUrl}/Orders/monthly-growth').replace(
        queryParameters: {
          if (year != null) 'year': year.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Unexpected response structure');
      } else {
        throw Exception('Failed to load monthly growth: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting monthly growth: $e');
      throw Exception('Error getting monthly growth: $e');
    }
  }

  // Lấy danh sách sản phẩm từ đơn hàng đã hoàn thành để đánh giá
  Future<List<Map<String, dynamic>>> getCompletedOrderProducts() async {
    try {
      final headers = await ApiService().getHeaders();
      final user = await UserApi().getCurrentUser();

      if (user == null) throw Exception('User not logged in');

      print('📦 Fetching completed order products for user: ${user.maTaiKhoan}');
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Orders/completed-products/${user.maTaiKhoan}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('📦 Completed Products API Response: ${response.statusCode}');
      print('📦 Completed Products API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> productsData = data['data'];
          print('✅ Found ${productsData.length} products from completed orders');
          
          return productsData.cast<Map<String, dynamic>>();
        } else {
          print('Unexpected response structure: $data');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('No completed order products found');
        return [];
      } else {
        throw Exception('Failed to load completed order products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting completed order products: $e');
      throw Exception('Error getting completed order products: $e');
    }
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    try {
      print('❌ Cancelling order: $orderId');
      final success = await updateOrderStatus(orderId, 'Đã hủy');
      if (success) {
        print('✅ Order cancelled successfully');
      }
      return success;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      throw Exception('Lỗi hủy đơn hàng: $e');
    }
  }

  // Kiểm tra xem đơn hàng có thể hủy không (chỉ khi chưa được xác nhận)
  bool canCancelOrder(String status) {
    final lowerStatus = status.toLowerCase();
    // Chỉ cho phép hủy khi: pending, chờ xác nhận, hoặc các status chưa được xác nhận
    return lowerStatus.contains('pending') ||
           lowerStatus.contains('chờ') ||
           lowerStatus.contains('waiting') ||
           (!lowerStatus.contains('confirmed') &&
            !lowerStatus.contains('đã xác nhận') &&
            !lowerStatus.contains('shipping') &&
            !lowerStatus.contains('đang giao') &&
            !lowerStatus.contains('delivered') &&
            !lowerStatus.contains('đã giao') &&
            !lowerStatus.contains('hoàn thành') &&
            !lowerStatus.contains('complete') &&
            !lowerStatus.contains('cancelled') &&
            !lowerStatus.contains('đã hủy'));
  }

  // Lấy thống kê doanh thu theo tháng
  Future<List<Map<String, dynamic>>> getMonthlyRevenue({int? year}) async {
    try {
      print('📊 Fetching monthly revenue statistics...');

      final headers = await ApiService().getHeaders();

      // Xây dựng URL với query parameters
      final uri = Uri.parse('${Constant().baseUrl}/Orders/monthly-revenue')
          .replace(
        queryParameters: {
          if (year != null) 'year': year.toString(),
        },
      );

      print('📊 Monthly Revenue URL: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📊 Monthly Revenue API Response: ${response.statusCode}');
      print('📊 Monthly Revenue API Body: ${response.body}');
      print('📊 Monthly Revenue Headers: $headers');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Monthly Revenue Data: $data');

        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> monthlyData = data['data'];
          return monthlyData
              .map((item) => {
                    'thang': item['thang'] as int,
                    'doanhThu': (item['doanhThu'] as num).toDouble(),
                  })
              .toList()
              .cast<Map<String, dynamic>>();
        } else {
          print('Unexpected monthly revenue response structure: $data');
          throw Exception('Unexpected response structure');
        }
      } else {
        throw Exception(
            'Failed to load monthly revenue: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting monthly revenue: $e');
      throw Exception('Error getting monthly revenue: $e');
    }
  }
}
