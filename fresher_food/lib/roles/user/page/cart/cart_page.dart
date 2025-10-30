import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/home/page/home_page.dart';
import 'package:fresher_food/roles/user/page/checkout/checkout_page.dart';
import 'package:fresher_food/services/api/cart_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

import '../../../../models/Cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  List<CartItem> _selectedItems = [];
  double tongTien = 0;
  double _selectedTotal = 0;
  int tongSoLuong = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await UserApi().isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
    
    if (isLoggedIn) {
      _loadCart();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCart() async {
    try {
      final cartResponse = await CartApi().getCart();
      setState(() {
        _cartItems = cartResponse.sanPham;
        tongTien = cartResponse.tongTien;
        tongSoLuong = cartResponse.tongSoLuong;
        _isLoading = false;
        _updateSelectedItems();
      });
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSelectedItems() {
    setState(() {
      _selectedItems = _cartItems.where((item) => item.isSelected).toList();
      _selectedTotal = _selectedItems.fold(0, (total, item) => total + item.thanhTien);
      _selectAll = _cartItems.isNotEmpty && _cartItems.every((item) => item.isSelected);
    });
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;
    
    setState(() {
      _selectAll = value;
      for (var item in _cartItems) {
        item.isSelected = value;
      }
      _updateSelectedItems();
    });
  }

  void _toggleItemSelection(CartItem cartItem, bool? value) {
    if (value == null) return;
    
    setState(() {
      final index = _cartItems.indexWhere((item) => item.maSanPham == cartItem.maSanPham);
      if (index != -1) {
        _cartItems[index].isSelected = value;
        _updateSelectedItems();
      }
    });
  }

  // Kiểm tra số lượng tồn kho trước khi thanh toán
  bool _checkStockBeforeCheckout() {
    for (var item in _selectedItems) {
      if (item.soLuong > item.soLuongTon) {
        _showStockWarning(item);
        return false;
      }
    }
    return true;
  }

  void _showStockWarning(CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Số lượng không đủ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sản phẩm "${item.tenSanPham}" chỉ còn ${item.soLuongTon} sản phẩm. Vui lòng điều chỉnh số lượng.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ĐÃ HIỂU'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon xác nhận
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Bạn có chắc muốn xóa "${cartItem.tenSanPham}" khỏi giỏ hàng?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        _removeFromCart(cartItem.maSanPham, cartItem.tenSanPham);
      }
    });
  }

  Future<void> _removeFromCart(String productId, String productName) async {
    try {
      final success = await CartApi().removeFromCart(productId);
      if (success) {
        setState(() {
          _cartItems.removeWhere((item) => item.maSanPham == productId);
          tongTien = _cartItems.fold(0, (total, item) => total + item.thanhTien);
          tongSoLuong = _cartItems.fold(0, (total, item) => total + item.soLuong);
          _updateSelectedItems();
        });
        
        _showSuccessSnackBar('Đã xóa "$productName" khỏi giỏ hàng');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xóa: $e');
    }
  }

  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade400,
                  size: 50,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Số lượng sẽ là 0. Bạn có muốn xóa sản phẩm này khỏi giỏ hàng?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      
      if (confirm == true) {
        _removeFromCart(cartItem.maSanPham, cartItem.tenSanPham);
      }
      return;
    }

    // Kiểm tra số lượng tồn kho
    if (newQuantity > cartItem.soLuongTon) {
      _showStockWarning(cartItem);
      return;
    }

    try {
      final success = await CartApi().updateCartItem(cartItem.maSanPham, newQuantity);
      if (success) {
        setState(() {
          final index = _cartItems.indexWhere((item) => item.maSanPham == cartItem.maSanPham);
          if (index != -1) {
            final updatedItem = cartItem.copyWith(
              soLuong: newQuantity,
              thanhTien: cartItem.giaBan * newQuantity,
            );
            _cartItems[index] = updatedItem;
            tongTien = _cartItems.fold(0, (total, item) => total + item.thanhTien);
            tongSoLuong = _cartItems.fold(0, (total, item) => total + item.soLuong);
            _updateSelectedItems();
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi cập nhật số lượng: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (m) => '${m[1]}.'
    );
  }

  void _handleCheckout() {
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar('Vui lòng chọn ít nhất một sản phẩm để thanh toán');
      return;
    }

    // Kiểm tra số lượng tồn kho trước khi chuyển trang
    if (!_checkStockBeforeCheckout()) {
      return;
    }

    // Điều hướng đến trang thanh toán
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          selectedItems: _selectedItems,
          totalAmount: _selectedTotal,
        ),
      ),
    ).then((_) {
      _loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 20, 
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _isLoggedIn
              ? _buildCartContent()
              : _buildLoginRequired(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải giỏ hàng...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vui lòng đăng nhập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để xem giỏ hàng của bạn',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng nhé!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to shop
                Navigator.of(context).push(HomePage() as Route<Object?>);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                'Mua sắm ngay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cartItem = _cartItems[index];
              return _buildCartItem(cartItem);
            },
          ),
        ),

        // Checkout Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Checkbox chọn tất cả
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _selectAll ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ] : null,
                    ),
                    child: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn tất cả',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Tổng tiền + Nút thanh toán
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '${_formatPrice(_selectedTotal)}đ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTotal > 0 
                          ? Colors.green.shade600 
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: _selectedTotal > 0 ? 3 : 0,
                    ),
                    onPressed: _selectedTotal > 0 ? _handleCheckout : null,
                    child: const Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem cartItem) {
    final isOutOfStock = cartItem.soLuongTon == 0;
    final isLowStock = cartItem.soLuong > cartItem.soLuongTon;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: isOutOfStock || isLowStock 
            ? Border.all(color: Colors.orange.shade300, width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox chọn sản phẩm
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: cartItem.isSelected ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Checkbox(
                    value: cartItem.isSelected && !isOutOfStock,
                    onChanged: isOutOfStock ? null : (value) => _toggleItemSelection(cartItem, value),
                    activeColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),

                // Ảnh sản phẩm
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    image: cartItem.anh.isNotEmpty 
                        ? DecorationImage(
                            image: NetworkImage(cartItem.anh),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cartItem.anh.isEmpty 
                      ? Center(
                          child: Text(
                            cartItem.tenSanPham.isNotEmpty ? cartItem.tenSanPham[0] : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : null,
                ),

                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cartItem.tenSanPham,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      Text(
                        '${_formatPrice(cartItem.giaBan)}đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                      
                      // Hiển thị cảnh báo số lượng tồn kho
                      if (isOutOfStock)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'Hết hàng',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (isLowStock)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Chỉ còn ${cartItem.soLuongTon} sản phẩm',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Bộ chọn số lượng
                      Container(
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade100 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 18, color: isOutOfStock ? Colors.grey.shade400 : Colors.grey.shade600),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: isOutOfStock ? null : () => _updateQuantity(cartItem, cartItem.soLuong - 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cartItem.soLuong}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock ? Colors.grey.shade400 : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 18, color: isOutOfStock ? Colors.grey.shade400 : Colors.green.shade600),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: isOutOfStock ? null : () => _updateQuantity(cartItem, cartItem.soLuong + 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tổng tiền và nút xóa
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(cartItem.thanhTien)}đ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                        padding: EdgeInsets.zero,
                        onPressed: () => _showDeleteConfirmation(cartItem),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}