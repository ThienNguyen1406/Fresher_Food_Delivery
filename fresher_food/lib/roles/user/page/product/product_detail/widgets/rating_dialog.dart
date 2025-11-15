import 'package:flutter/material.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';

class RatingDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Rating? userRating;
  final VoidCallback onRatingSubmitted;
  final ProductDetailProvider productDetailProvider;

  const RatingDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.userRating,
    required this.onRatingSubmitted,
    required this.productDetailProvider,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedStars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.userRating != null) {
      _selectedStars = widget.userRating!.soSao;
      _reviewController.text = widget.userRating!.noiDung ?? '';
    }
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rating = Rating(
        maSanPham: widget.productId,
        maTaiKhoan: '', // Will be filled by service
        soSao: _selectedStars,
        noiDung: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      final success = await widget.productDetailProvider.submitRating(rating);
      if (success) {
        widget.onRatingSubmitted();
      } else {
        throw Exception('Không thể gửi đánh giá');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userRating != null && widget.userRating!.soSao > 0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Chỉnh sửa đánh giá' : 'Đánh giá sản phẩm',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.productName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Star rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStars = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starIndex <= _selectedStars
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Review text
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('HỦY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEdit ? 'CẬP NHẬT' : 'GỬI ĐÁNH GIÁ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
