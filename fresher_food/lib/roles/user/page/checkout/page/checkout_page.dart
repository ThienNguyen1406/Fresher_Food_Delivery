import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/checkout/provider/checkout_provider.dart';
import 'package:provider/provider.dart';
import 'package:fresher_food/models/Cart.dart';
import 'package:fresher_food/models/Coupon.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> selectedItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _noteController = TextEditingController();
  Timer? _successTimer;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _secondaryColor = const Color(0xFF059669);
  final Color _accentColor = const Color(0xFF8B5CF6);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    // Không gọi context.read ở đây vì Provider chưa sẵn sàng
  }

  void _initializeProvider(CheckoutProvider provider) {
    provider.loadUserInfo();
    provider.loadPaymentMethods();
    provider.loadAvailableCoupons();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CheckoutProvider(
        selectedItems: widget.selectedItems,
        totalAmount: widget.totalAmount,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(
            'Thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              fontSize: 18,
            ),
          ),
          backgroundColor: _surfaceColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _textPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: Consumer<CheckoutProvider>(
          builder: (context, provider, child) {
            // Khởi tạo provider khi widget được build lần đầu
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!provider.isLoading && 
                  provider.state.name.isEmpty && 
                  provider.state.phone.isEmpty) {
                _initializeProvider(provider);
              }
            });

            if (provider.isLoading || provider.isProcessingPayment) {
              return _buildLoadingScreen();
            }
            return _buildCheckoutContent(provider);
          },
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(CheckoutProvider provider) {
    _noteController.text = provider.state.note;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Thông tin giao hàng', Icons.local_shipping_outlined),
          _buildDeliveryInfoCard(provider),

          const SizedBox(height: 28),

          _buildSectionHeader('Ghi chú đơn hàng', Icons.note_add_outlined),
          _buildNoteCard(provider),

          const SizedBox(height: 28),

          _buildSectionHeader('Mã giảm giá', Icons.discount_outlined),
          _buildCouponSection(provider),

          const SizedBox(height: 28),

          _buildSectionHeader('Phương thức thanh toán', Icons.payment_outlined),
          _buildPaymentMethod(provider),

          const SizedBox(height: 28),

          _buildSectionHeader('Sản phẩm đã chọn', Icons.shopping_bag_outlined),
          _buildSelectedProducts(provider),

          const SizedBox(height: 28),

          _buildTotalSection(provider),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhận hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.person_outline, 'Họ và tên', provider.state.name),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_iphone_outlined, 'Số điện thoại', provider.state.phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', provider.state.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _textSecondary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'Chưa có thông tin',
                style: TextStyle(
                  fontSize: 14,
                  color: value.isNotEmpty ? _textPrimary : _textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cho đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            onChanged: provider.updateNote,
            maxLines: 3,
            style: TextStyle(color: _textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Giao hàng giờ hành chính, gọi điện trước khi giao...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã giảm giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (provider.selectedCoupon == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCouponSelectionDialog(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _backgroundColor,
                  foregroundColor: _textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.discount_outlined, color: _primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.discount_outlined, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.selectedCoupon!.code,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        if (provider.selectedCoupon?.moTa != null && provider.selectedCoupon!.moTa.isNotEmpty)
                          Text(
                            provider.selectedCoupon!.moTa,
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        Text(
                          'Giảm ${provider.formatPrice(provider.selectedCoupon!.giaTri)}đ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => provider.removeCoupon(),
                    icon: Icon(Icons.close, color: _textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCouponSelectionDialog(CheckoutProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        color: _primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chọn mã giảm giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: provider.state.availableCoupons.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: _textSecondary.withOpacity(0.5),
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có mã giảm giá nào',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.state.availableCoupons.length,
                    itemBuilder: (context, index) {
                      final coupon = provider.state.availableCoupons[index];
                      final isSelected = provider.selectedCoupon?.idPhieuGiamGia == coupon.idPhieuGiamGia;

                      return _buildCouponItem(provider, coupon, isSelected);
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                          ),
                          child: const Text('HỦY'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('XONG'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponItem(CheckoutProvider provider, PhieuGiamGia coupon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          provider.applyCoupon(coupon);
          _showSuccessSnackBar('Đã áp dụng mã giảm giá ${coupon.code}');
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor.withOpacity(0.1) : _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.discount_outlined,
                  color: isSelected ? Colors.white : _textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _primaryColor : _textPrimary,
                      ),
                    ),
                    if (coupon.moTa.isNotEmpty)
                      Text(
                        coupon.moTa,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _primaryColor.withOpacity(0.8) : _textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Giảm ${provider.formatPrice(coupon.giaTri)}đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isSelected ? _primaryColor : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(CheckoutProvider provider) {
    if (provider.paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: provider.paymentMethods.map((pay) {
          final isSelected = provider.selectedPaymentId == pay.Id_Pay;
          final payName = pay.Pay_name.toLowerCase();
          final isCOD = payName.contains('cod');
          final isMoMo = payName.contains('momo');

          IconData icon;
          Color color;
          String subtitle;

          if (isCOD) {
            icon = Icons.money_outlined;
            color = _primaryColor;
            subtitle = 'Thanh toán bằng tiền mặt khi nhận hàng';
          } else if (isMoMo) {
            icon = Icons.phone_iphone_outlined;
            color = Colors.pink;
            subtitle = 'Thanh toán qua ứng dụng MoMo';
          } else {
            icon = Icons.account_balance_outlined;
            color = _accentColor;
            subtitle = pay.Pay_name.isNotEmpty 
                ? 'Thanh toán qua ${pay.Pay_name}'
                : 'Thanh toán trực tuyến';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentOption(
              provider: provider,
              value: pay.Id_Pay,
              title: pay.Pay_name.isNotEmpty ? pay.Pay_name : 'Thanh toán trực tuyến',
              subtitle: subtitle,
              icon: icon,
              color: color,
              isSelected: isSelected,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentOption({
    required CheckoutProvider provider,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: provider.selectedPaymentId,
        onChanged: (value) {
          provider.updatePaymentMethod(
            value!.contains('cod') ? 'cod' : value.contains('momo') ? 'momo' : 'banking',
            value,
          );
        },
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : _textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? color.withOpacity(0.8) : _textSecondary,
            fontSize: 13,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? color : _textSecondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : _textSecondary,
            size: 20,
          ),
        ),
        activeColor: color,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectedProducts(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: provider.selectedItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _backgroundColor,
                    image: item.anh.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(item.anh),
                      fit: BoxFit.cover,
                    )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: item.anh.isEmpty ? Icon(
                    Icons.shopping_bag_outlined,
                    color: _textSecondary.withOpacity(0.5),
                  ) : null,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenSanPham,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${provider.formatPrice(item.giaBan)}đ x ${item.soLuong}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tồn kho: ${item.soLuongTon}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.soLuong > item.soLuongTon ? Colors.orange.shade600 : _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${provider.formatPrice(item.thanhTien)}đ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalSection(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Tổng tiền hàng', provider.totalAmount, provider: provider),
          if (provider.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildTotalRow('Giảm giá', -provider.discountAmount, provider: provider, isDiscount: true),
          ],
          const SizedBox(height: 10),
          _buildTotalRow('Phí vận chuyển', provider.shippingFee, provider: provider),
          const SizedBox(height: 10),
          _buildDivider(),
          const SizedBox(height: 10),
          _buildTotalRow('Tổng thanh toán', provider.finalAmount, provider: provider, isTotal: true),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isProcessingPayment ? null : () => _placeOrder(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isProcessingPayment ? Colors.grey : _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: provider.isProcessingPayment ? 0 : 3,
                shadowColor: provider.isProcessingPayment ? Colors.transparent : _primaryColor.withOpacity(0.4),
              ),
              child: provider.isProcessingPayment
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ĐẶT HÀNG NGAY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: _textSecondary.withOpacity(0.2),
    );
  }

  Widget _buildTotalRow(String label, double amount, {required CheckoutProvider provider, bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _textPrimary : _textSecondary,
          ),
        ),
        Text(
          '${isDiscount && amount > 0 ? '-' : ''}${provider.formatPrice(amount)}đ',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? _primaryColor
                : isDiscount
                ? Colors.green
                : _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang xử lý đơn hàng...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng không thoát ứng dụng',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CheckoutProvider provider) async {
    if (!provider.validateForm()) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin giao hàng');
      return;
    }

    final outOfStockItem = provider.getOutOfStockItem();
    if (outOfStockItem != null) {
      _showStockErrorDialog(outOfStockItem);
      return;
    }

    provider.updateProcessingPayment(true);

    try {
      if (provider.paymentMethod == 'cod') {
        await _processCODPayment(provider);
      } else if (provider.paymentMethod == 'momo' || provider.paymentMethod == 'banking') {
        await _processMoMoPayment(provider);
      } else {
        _showErrorSnackBar('Phương thức thanh toán không được hỗ trợ');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi trong quá trình thanh toán: $e');
    } finally {
      provider.updateProcessingPayment(false);
    }
  }

  Future<void> _processCODPayment(CheckoutProvider provider) async {
    _showProcessingDialog('Đang xử lý đơn hàng...');

    try {
      final success = await provider.createOrder('cod');
      Navigator.of(context).pop(); // Đóng dialog loading

      if (success) {
        _showSuccessScreen();
      } else {
        _showErrorSnackBar('Không thể tạo đơn hàng');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Lỗi khi xử lý thanh toán COD: $e');
    }
  }

  Future<void> _processMoMoPayment(CheckoutProvider provider) async {
    _showProcessingDialog('Đang chuyển hướng đến MoMo...');
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();

    try {
      final success = await provider.createOrder('momo');
      if (success) {
        _showSuccessScreen();
      } else {
        _showErrorSnackBar('Không thể tạo đơn hàng sau thanh toán MoMo');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xử lý thanh toán MoMo: $e');
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text('Thanh toán thành công'),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: _buildSuccessContent(),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Thanh toán thành công!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi.\nĐơn hàng đang được xử lý và sẽ được giao sớm nhất.',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: _primaryColor.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Về trang chủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStockErrorDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'Số lượng không đủ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sản phẩm "${item.tenSanPham}" chỉ còn ${item.soLuongTon} sản phẩm trong kho. Bạn đã chọn ${item.soLuong} sản phẩm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Quay lại giỏ hàng
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('QUAY LẠI GIỎ HÀNG'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade300,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: _primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}