import 'package:flutter/material.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:fresher_food/services/api/coupon_api.dart';
import 'package:provider/provider.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PhieuGiamGia> _allCoupons = [];
  List<PhieuGiamGia> _displayedCoupons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoupons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      print('🔄 Bắt đầu tải danh sách mã giảm giá...');

      final couponApi = Provider.of<CouponApi>(context, listen: false);
      final coupons = await couponApi.getAllCoupons();

      if (!mounted) return;

      print('✅ Tải thành công ${coupons.length} mã giảm giá');

      setState(() {
        _allCoupons = coupons;
        _displayedCoupons = coupons;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('❌ Lỗi tải mã giảm giá: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _allCoupons = [];
        _displayedCoupons = [];
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải mã giảm giá: ${_errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _filterCoupons();
  }

  void _filterCoupons() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _displayedCoupons = _allCoupons;
      });
      return;
    }

    final filtered = _allCoupons.where((coupon) {
      final codeMatch = coupon.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final descriptionMatch = coupon.moTa.toLowerCase().contains(_searchQuery.toLowerCase());
      return codeMatch || descriptionMatch;
    }).toList();

    setState(() {
      _displayedCoupons = filtered;
    });
  }

  Future<void> _searchCoupons(String query) async {
    if (query.isEmpty) {
      await _loadCoupons();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      print('🔍 Tìm kiếm mã giảm giá với từ khóa: $query');

      final apiService = Provider.of<CouponApi>(context, listen: false);
      final searchResults = await apiService.searchCoupons(query);

      setState(() {
        _displayedCoupons = searchResults;
        _isLoading = false;
      });

      print('✅ Tìm thấy ${searchResults.length} kết quả');
    } catch (e) {
      print('❌ Lỗi tìm kiếm mã giảm giá: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Lỗi tìm kiếm: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _loadCoupons();
  }

  void _copyVoucherCode(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getVoucherColor(double giaTri) {
    if (giaTri >= 100000) {
      return const Color(0xFFFF6B6B);
    } else if (giaTri >= 50000) {
      return const Color(0xFFFFA726);
    } else if (giaTri >= 20000) {
      return const Color(0xFF667EEA);
    } else {
      return const Color(0xFF00C896);
    }
  }

  String _getDiscountText(PhieuGiamGia voucher) {
    if (voucher.giaTri <= 100) {
      return '${voucher.giaTri}%';
    } else {
      return '${_formatPrice(voucher.giaTri.toInt())}';
    }
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)}Tr';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mã giảm giá',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Section
          _buildSearchSection(),

          // Stats Info
          _buildStatsInfo(),

          // Vouchers List
          Expanded(
            child: _buildVouchersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mã giảm giá...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _searchCoupons,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 18),
                onPressed: _clearSearch,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsInfo() {
    String statusText;
    Color statusColor = Colors.grey.shade600;

    if (_hasError) {
      statusText = 'Đã xảy ra lỗi';
      statusColor = Colors.red;
    } else if (_searchQuery.isEmpty) {
      statusText = 'Tất cả mã giảm giá';
    } else {
      statusText = 'Kết quả tìm kiếm cho "$_searchQuery"';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${_displayedCoupons.length} mã giảm giá',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _hasError ? Colors.red : const Color(0xFF00C896),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C896)),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải mã giảm giá...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadCoupons,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayedCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có mã giảm giá nào'
                  : 'Không tìm thấy mã giảm giá phù hợp',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hiển thị tất cả'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _displayedCoupons.length,
      itemBuilder: (context, index) {
        final voucher = _displayedCoupons[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildVoucherCard(voucher),
        );
      },
    );
  }

  Widget _buildVoucherCard(PhieuGiamGia voucher) {
    final color = _getVoucherColor(voucher.giaTri);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Discount Badge
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDiscountText(voucher),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GIẢM GIÁ',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Voucher Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.moTa.isNotEmpty ? voucher.moTa : 'Mã giảm giá đặc biệt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Copy Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _copyVoucherCode(voucher.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sao chép',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
}