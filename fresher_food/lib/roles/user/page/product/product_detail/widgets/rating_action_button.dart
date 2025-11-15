import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_dialog.dart';

class RatingActionButton extends StatelessWidget {
  final ProductDetailProvider provider;

  const RatingActionButton({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            provider.hasUserRated ? Icons.star : Icons.star_outline,
            color: provider.hasUserRated ? Colors.amber : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.hasUserRated
                      ? 'Bạn đã đánh giá sản phẩm này'
                      : 'Chia sẻ đánh giá của bạn',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (provider.hasUserRated && provider.userRating != null)
                  Text(
                    '${provider.userRating!.soSao} sao - ${provider.userRating!.noiDung ?? "Không có nhận xét"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (provider.hasUserRated)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showRatingDialog(context),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteRating(context),
                  color: Colors.red,
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _showRatingDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('ĐÁNH GIÁ NGAY'),
            ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RatingDialog(
          productId: provider.product!.maSanPham,
          productName: provider.product!.tenSanPham,
          userRating: provider.userRating,
          onRatingSubmitted: () {
            provider.loadProductDetail(provider.product!.maSanPham);
            Navigator.of(context).pop();
          },
          productDetailProvider: provider,
        );
      },
    );
  }

  Future<void> _deleteRating(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa đánh giá'),
          content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('XÓA', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success =
            await provider.deleteRating(provider.product!.maSanPham);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa đánh giá thành công')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa đánh giá')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa đánh giá: $e')),
          );
        }
      }
    }
  }
}
