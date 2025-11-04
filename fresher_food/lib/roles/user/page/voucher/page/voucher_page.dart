import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/voucher/provider/voucher_provider.dart';
import 'package:fresher_food/roles/user/page/voucher/provider/voucher_state.dart';
import 'package:fresher_food/models/Coupon.dart';
import 'package:provider/provider.dart';


class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = VoucherProvider();
        provider.onError = (message) => _showErrorSnackBar(context, message);
        provider.onSuccess = (message) => _showSuccessSnackBar(context, message);
        return provider;
      },
      child: Scaffold(
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
        body: Consumer<VoucherProvider>(
          builder: (context, provider, child) {
            return _VoucherContent(provider: provider);
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _VoucherContent extends StatelessWidget {
  final VoucherProvider provider;

  const _VoucherContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final state = provider.state;

    return Column(
      children: [
        // Search Section
        _buildSearchSection(provider),
        
        // Stats Info
        _buildStatsInfo(state),
        
        // Vouchers List
        Expanded(
          child: _buildVouchersList(provider, state),
        ),
      ],
    );
  }

  Widget _buildSearchSection(VoucherProvider provider) {
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
                controller: provider.searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mã giảm giá...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: provider.searchCoupons,
              ),
            ),
            if (provider.state.searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 18),
                onPressed: provider.clearSearch,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsInfo(VoucherState state) {
    String statusText;
    Color statusColor = Colors.grey.shade600;

    if (state.hasError) {
      statusText = 'Đã xảy ra lỗi';
      statusColor = Colors.red;
    } else if (state.searchQuery.isEmpty) {
      statusText = 'Tất cả mã giảm giá';
    } else {
      statusText = 'Kết quả tìm kiếm cho "${state.searchQuery}"';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${state.displayedCoupons.length} mã giảm giá',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: state.hasError ? Colors.red : const Color(0xFF00C896),
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

  Widget _buildVouchersList(VoucherProvider provider, VoucherState state) {
    if (state.isLoading) {
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

    if (state.hasError) {
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
                state.errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: provider.loadCoupons,
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

    if (state.displayedCoupons.isEmpty) {
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
              state.searchQuery.isEmpty
                  ? 'Chưa có mã giảm giá nào'
                  : 'Không tìm thấy mã giảm giá phù hợp',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (state.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.clearSearch,
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
      itemCount: state.displayedCoupons.length,
      itemBuilder: (context, index) {
        final voucher = state.displayedCoupons[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildVoucherCard(provider, voucher),
        );
      },
    );
  }

  Widget _buildVoucherCard(VoucherProvider provider, PhieuGiamGia voucher) {
    final color = provider.getVoucherColor(voucher.giaTri);

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
                  provider.getDiscountText(voucher),
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
                      onTap: () => provider.copyVoucherCode(voucher.code),
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