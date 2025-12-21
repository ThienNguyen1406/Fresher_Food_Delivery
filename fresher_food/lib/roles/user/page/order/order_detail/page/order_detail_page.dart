// pages/orderdetail_page.dart
import 'package:flutter/material.dart';
import 'package:fresher_food/models/Order.dart';
import 'package:fresher_food/roles/user/page/order/order_detail/provider/order_detail_provider.dart';
import 'package:fresher_food/utils/app_localizations.dart';
import 'package:provider/provider.dart';


class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.3),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Chi tiết đơn hàng',
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
          Consumer<OrderDetailProvider>(
            builder: (context, orderDetailProvider, child) {
              if (orderDetailProvider.isLoading) {
                return _buildLoadingSliver();
              } else if (orderDetailProvider.errorMessage.isNotEmpty) {
                return _buildErrorSliver(orderDetailProvider);
              } else if (orderDetailProvider.order == null) {
                return _buildEmptySliver();
              } else {
                return _buildOrderDetailSliver(orderDetailProvider);
              }
            },
          ),
        ],
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
            'Đang tải chi tiết đơn hàng...',
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

  Widget _buildErrorSliver(OrderDetailProvider orderDetailProvider) {
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
              orderDetailProvider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => orderDetailProvider.retryLoading(widget.orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
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
              'Không tìm thấy đơn hàng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đơn hàng không tồn tại hoặc đã bị xóa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailSliver(OrderDetailProvider orderDetailProvider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildOrderTrackingCard(orderDetailProvider),
          const SizedBox(height: 20),
          _buildOrderInfoCard(orderDetailProvider),
          const SizedBox(height: 20),
          _buildProductListCard(orderDetailProvider),
          const SizedBox(height: 20),
          _buildPaymentInfoCard(orderDetailProvider),
          if (orderDetailProvider.canCancelOrder()) ...[
            const SizedBox(height: 20),
            _buildCancelOrderButton(orderDetailProvider),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderDetailProvider orderDetailProvider) {
    final order = orderDetailProvider.order!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.9),
                          orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          orderDetailProvider.getStatusIcon(order.trangThai),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orderDetailProvider.getStatusText(order.trangThai),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              _buildDetailInfoRow(
                provider: orderDetailProvider,
                icon: Icons.calendar_today_rounded,
                title: 'Ngày đặt hàng',
                value: orderDetailProvider.formatDate(order.ngayDat),
                subValue: orderDetailProvider.formatTime(order.ngayDat),
              ),
              if (order.phuongThucThanhToan != null &&
                  order.phuongThucThanhToan!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.payment_rounded,
                  title: 'Phương thức thanh toán',
                  value: order.phuongThucThanhToan!,
                ),
              _buildDetailInfoRow(
                provider: orderDetailProvider,
                icon: Icons.credit_card_rounded,
                title: 'Trạng thái thanh toán',
                value: order.trangThaiThanhToan,
                valueColor: order.trangThaiThanhToan.toLowerCase() == 'paid'
                    ? const Color(0xFF66BB6A)
                    : Colors.orange,
              ),
              if (order.soDienThoai != null && order.soDienThoai!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.phone_rounded,
                  title: 'Số điện thoại',
                  value: order.soDienThoai!,
                ),
              if (order.diaChiGiaoHang != null &&
                  order.diaChiGiaoHang!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.location_on_rounded,
                  title: 'Địa chỉ giao hàng',
                  value: order.diaChiGiaoHang!,
                  isMultiLine: true,
                ),
              if (order.ghiChu != null && order.ghiChu!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.note_rounded,
                  title: 'Ghi chú',
                  value: order.ghiChu!,
                  isMultiLine: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListCard(OrderDetailProvider orderDetailProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sản phẩm đã đặt',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 20),
              ...orderDetailProvider.orderDetails.asMap().entries.map((entry) {
                final index = entry.key;
                final detail = entry.value;
                return _buildProductItem(orderDetailProvider, detail, index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(
      OrderDetailProvider orderDetailProvider, OrderDetail detail, int index) {
    final subtotal = detail.giaBan * detail.soLuong;

    return Container(
      margin: EdgeInsets.only(
          bottom:
              index == orderDetailProvider.orderDetails.length - 1 ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8F5E8),
                  const Color(0xFFC8E6C9),
                ],
              ),
            ),
            child: Icon(
              Icons.image_rounded,
              size: 28,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.tenSanPham,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Số lượng: ${detail.soLuong}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderDetailProvider.formatCurrency(detail.giaBan),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      orderDetailProvider.formatCurrency(subtotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(OrderDetailProvider orderDetailProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thông tin thanh toán',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Tổng tiền hàng',
                value: orderDetailProvider
                    .formatCurrency(orderDetailProvider.totalAmount),
              ),
              const SizedBox(height: 12),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Phí vận chuyển',
                value: 'Miễn phí',
                valueColor: const Color(0xFF66BB6A),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Tổng thanh toán',
                value: orderDetailProvider
                    .formatCurrency(orderDetailProvider.totalAmount),
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow({
    required OrderDetailProvider provider,
    required IconData icon,
    required String title,
    required String value,
    String? subValue,
    Color? valueColor,
    bool isMultiLine = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
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
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMultiLine)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: valueColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: valueColor ?? Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subValue != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subValue,
                            style: TextStyle(
                              fontSize: 11,
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

  Widget _buildPaymentRow({
    required OrderDetailProvider provider,
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            color: valueColor ??
                (isTotal ? const Color(0xFF4CAF50) : Colors.black87),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTrackingCard(OrderDetailProvider orderDetailProvider) {
    final steps = orderDetailProvider.getTrackingSteps();
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.track_changes_rounded,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Theo dõi đơn hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isLast = index == steps.length - 1;
                
                return _buildTrackingStep(
                  step: step,
                  isLast: isLast,
                  index: index,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingStep({
    required Map<String, dynamic> step,
    required bool isLast,
    required int index,
  }) {
    final status = step['status'] as String;
    final title = step['title'] as String;
    final icon = step['icon'] as IconData;
    
    Color stepColor;
    Color iconColor;
    Color textColor;
    
    if (status == 'completed') {
      stepColor = const Color(0xFF4CAF50);
      iconColor = Colors.white;
      textColor = Colors.black87;
    } else if (status == 'current') {
      stepColor = const Color(0xFF42A5F5);
      iconColor = Colors.white;
      textColor = Colors.black87;
    } else if (status == 'cancelled') {
      stepColor = const Color(0xFFEF5350);
      iconColor = Colors.white;
      textColor = Colors.black87;
    } else {
      stepColor = Colors.grey.shade300;
      iconColor = Colors.grey.shade600;
      textColor = Colors.grey.shade600;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
                boxShadow: status == 'completed' || status == 'current'
                    ? [
                        BoxShadow(
                          color: stepColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'completed' 
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (status == 'current')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Đang xử lý...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelOrderButton(OrderDetailProvider orderDetailProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hủy đơn hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bạn có thể hủy đơn hàng này vì chưa được xác nhận',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCancelOrderDialog(orderDetailProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hủy đơn hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelOrderDialog(OrderDetailProvider orderDetailProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xác nhận hủy đơn hàng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Không',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await orderDetailProvider.cancelOrder();
                if (mounted) {
                  final localizations = AppLocalizations.of(context)!;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(localizations.orderCancelledSuccessfully),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(localizations.cannotCancelOrder),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Có, hủy đơn hàng',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
                Icons.receipt_long_rounded,
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(const Color(0xFF4CAF50)),
                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
