// pages/orderlist_page.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_list/provider/order_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/roles/user/route/app_route.dart';

/// Màn hình danh sách đơn hàng - hiển thị tất cả đơn hàng của người dùng
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  /// Khối khởi tạo: Load danh sách đơn hàng từ server
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderListProvider>().loadOrders();
    });
  }

  /// Khối giao diện chính: Hiển thị loading, error, empty hoặc danh sách đơn hàng
  Future<void> _refreshOrders(OrderListProvider provider) async {
    await provider.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Consumer<OrderListProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => _refreshOrders(provider),
            color: const Color(0xFF4CAF50),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.3),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Đơn hàng của tôi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E7D32),
                      const Color(0xFF4CAF50),
                    ],
                  ),
                ),
              ),
            ),
          ),

                Consumer<OrderListProvider>(
                  builder: (context, orderListProvider, child) {
                    if (orderListProvider.isLoading) {
                      return _buildLoadingSliver();
                    } else if (orderListProvider.errorMessage.isNotEmpty) {
                      return _buildErrorSliver(orderListProvider);
                    } else if (orderListProvider.orders.isEmpty) {
                      return _buildEmptySliver();
                    } else {
                      return _buildOrderListSliver(orderListProvider);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingAnimation(),
          const SizedBox(height: 24),
          Text(
            'Đang tải đơn hàng...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSliver(OrderListProvider orderListProvider) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              orderListProvider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                return ElevatedButton(
                  onPressed: orderListProvider.retryLoading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.green.shade400
                        : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isDark ? 6 : 2,
                    shadowColor: isDark
                        ? Colors.green.shade400.withOpacity(0.5)
                        : const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Thử lại',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE8F5E8),
                    const Color(0xFFC8E6C9),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 70,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có đơn hàng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có đơn hàng nào.\nHãy khám phá và mua sắm các sản phẩm chất lượng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mua sắm ngay',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderListSliver(OrderListProvider orderListProvider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = orderListProvider.orders[index];
            return _buildOrderCard(orderListProvider, order, index);
          },
          childCount: orderListProvider.orders.length,
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderListProvider orderListProvider, Order order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            AppRoute.toOrderDetail(context, order.maDonHang);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã đơn hàng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.maDonHang,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              orderListProvider.getStatusColor(order.trangThai).withOpacity(0.9),
                              orderListProvider.getStatusColor(order.trangThai).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: orderListProvider.getStatusColor(order.trangThai).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              orderListProvider.getStatusIcon(order.trangThai),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              orderListProvider.getStatusText(order.trangThai),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    provider: orderListProvider,
                    icon: Icons.calendar_today_rounded,
                    title: 'Ngày đặt',
                    value: orderListProvider.formatDate(order.ngayDat),
                    subValue: orderListProvider.formatTime(order.ngayDat),
                  ),
                  
                  if (order.phuongThucThanhToan != null && order.phuongThucThanhToan!.isNotEmpty)
                    _buildInfoRow(
                      provider: orderListProvider,
                      icon: Icons.payment_rounded,
                      title: 'Phương thức thanh toán',
                      value: order.phuongThucThanhToan!,
                    ),
                  
                  if (order.diaChiGiaoHang != null && order.diaChiGiaoHang!.isNotEmpty)
                    _buildInfoRow(
                      provider: orderListProvider,
                      icon: Icons.location_on_rounded,
                      title: 'Địa chỉ giao hàng',
                      value: order.diaChiGiaoHang!,
                      isMultiLine: true,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.9),
                          const Color(0xFF2E7D32).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xem chi tiết đơn hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required OrderListProvider provider,
    required IconData icon,
    required String title,
    required String value,
    String? subValue,
    bool isMultiLine = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isMultiLine)
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subValue != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subValue,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                size: 30,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF4CAF50)),
                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}