import 'package:flutter/material.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/roles/user/page/product/product_review/provider/product_review_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_review/provider/product_review_state.dart';
import 'package:provider/provider.dart';


class ProductReviewPage extends StatefulWidget {
  final String productId;

  const ProductReviewPage({
    super.key,
    required this.productId, 
  });

  @override
  State<ProductReviewPage> createState() => _ProductReviewPageState();
}

class _ProductReviewPageState extends State<ProductReviewPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = ProductReviewProvider(
          productId: widget.productId,
        );
        provider.onError = (message) => _showErrorSnackBar(context, message);
        provider.onSuccess = (message) => _showSuccessSnackBar(context, message);
        return provider;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Đánh giá sản phẩm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            return _ProductReviewContent(provider: provider);
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ProductReviewContent extends StatelessWidget {
  final ProductReviewProvider provider;

  const _ProductReviewContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final state = provider.state;

    return state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: provider.reloadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRatingHeader(context, provider, state),
                  const SizedBox(height: 24),
                  _buildReviewsList(provider, state),
                ],
              ),
            ),
          );
  }

  Widget _buildRatingHeader(
      BuildContext context, ProductReviewProvider provider, ProductReviewState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: provider.surfaceColor,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá sản phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.productName,
                      style: TextStyle(
                        fontSize: 14,
                        color: provider.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    state.ratingStats?.averageRating.toStringAsFixed(1) ?? '0.0',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: provider.primaryColor,
                    ),
                  ),
                  _buildStarRating(state.ratingStats?.averageRating ?? 0, provider, size: 20),
                  Text(
                    '${state.ratingStats?.totalRatings ?? 0} đánh giá',
                    style: TextStyle(
                      fontSize: 12,
                      color: provider.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUserReviewSection(context, provider, state),
        ],
      ),
    );
  }

  Widget _buildUserReviewSection(
      BuildContext context, ProductReviewProvider provider, ProductReviewState state) {
    final hasUserReviewed = state.userReview != null && state.userReview!.soSao > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: provider.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasUserReviewed ? Icons.edit_outlined : Icons.rate_review_outlined,
                color: provider.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasUserReviewed ? 'Đánh giá của bạn' : 'Viết đánh giá',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: provider.textPrimary,
                ),
              ),
              const Spacer(),
              if (hasUserReviewed && !state.isEditMode)
                Row(
                  children: [
                    IconButton(
                      onPressed: provider.startEditing,
                      icon: Icon(Icons.edit, color: provider.primaryColor, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showDeleteDialog(context, provider),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          if (hasUserReviewed && !state.isEditMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStarRating(state.userReview!.soSao.toDouble(), provider),
                const SizedBox(width: 8),
                if (state.userReview!.noiDung != null && state.userReview!.noiDung!.isNotEmpty)
                  Expanded(
                    child: Text(
                      state.userReview!.noiDung!,
                      style: TextStyle(
                        fontSize: 14,
                        color: provider.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Center(child: _buildInteractiveStarRating(provider, state)),
            const SizedBox(height: 16),
            TextField(
              controller: provider.reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                hintStyle: TextStyle(color: provider.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: provider.textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: provider.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : provider.submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(hasUserReviewed ? 'CẬP NHẬT ĐÁNH GIÁ' : 'GỬI ĐÁNH GIÁ'),
              ),
            ),
            if (hasUserReviewed && state.isEditMode) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: provider.cancelEditing,
                  child: Text(
                    'HỦY',
                    style: TextStyle(color: provider.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveStarRating(ProductReviewProvider provider, ProductReviewState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => provider.updateSelectedStars(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= state.selectedStars ? Icons.star : Icons.star_border,
              color: provider.starColor,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarRating(double rating, ProductReviewProvider provider, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return Icon(
          starIndex <= rating ? Icons.star : Icons.star_border,
          color: provider.starColor,
          size: size,
        );
      }),
    );
  }

  Widget _buildReviewsList(ProductReviewProvider provider, ProductReviewState state) {
    final otherReviews = state.reviews
        .where((review) => review.maTaiKhoan != state.userReview?.maTaiKhoan)
        .toList();

    if (otherReviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.reviews_outlined,
              color: provider.textSecondary.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào từ người dùng khác',
              style: TextStyle(
                fontSize: 16,
                color: provider.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Đánh giá từ người dùng (${otherReviews.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: provider.textPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherReviews.length,
          itemBuilder: (context, index) {
            final review = otherReviews[index];
            return _buildReviewItem(review, provider);
          },
        ),
      ],
    );
  }

  Widget _buildReviewItem(Rating review, ProductReviewProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: provider.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: provider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Người dùng ${review.maTaiKhoan.substring(0, 6)}...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: provider.textPrimary,
                      ),
                    ),
                    _buildStarRating(review.soSao.toDouble(), provider, size: 14),
                  ],
                ),
              ),
            ],
          ),
          if (review.noiDung != null && review.noiDung!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.noiDung!,
              style: TextStyle(
                fontSize: 14,
                color: provider.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, ProductReviewProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: provider.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xóa đánh giá',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: provider.textPrimary,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa đánh giá này?',
            style: TextStyle(color: provider.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'HỦY',
                style: TextStyle(color: provider.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'XÓA',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      provider.deleteReview();
    }
  }
}
