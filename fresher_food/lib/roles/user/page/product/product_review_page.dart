import 'package:flutter/material.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/services/api/rating_api.dart';
import 'package:fresher_food/services/api/user_api.dart';

class ProductReviewPage extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductReviewPage> createState() => _ProductReviewPageState();
}

class _ProductReviewPageState extends State<ProductReviewPage> {
  final TextEditingController _reviewController = TextEditingController();

  List<Rating> _reviews = [];
  RatingStats? _ratingStats;
  Rating? _userReview;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _selectedStars = 0;
  bool _isEditMode = false;

  // Color scheme
  final Color _primaryColor = const Color(0xFF10B981);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _starColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load reviews và stats song song
      final reviewsFuture = RatingApi().getRatingsByProduct(widget.productId);
      final statsFuture = RatingApi().getProductRatingStats(widget.productId);
      final userReviewFuture =
          RatingApi().getUserRatingForProduct(widget.productId);

      final results = await Future.wait([
        reviewsFuture,
        statsFuture,
        userReviewFuture,
      ], eagerError: true);

      final reviews = results[0] as List<Rating>;
      final stats = results[1] as RatingStats;
      final userReview = results[2] as Rating?;

      setState(() {
        _reviews = reviews;
        _ratingStats = stats;
        _userReview = userReview;
        if (_userReview != null) {
          _selectedStars = _userReview!.soSao;
          _reviewController.text = _userReview!.noiDung ?? '';
        }
      });
    } catch (e) {
      print('Error loading reviews: $e');
      _showErrorSnackBar('Lỗi tải đánh giá: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_selectedStars == 0) {
      _showErrorSnackBar('Vui lòng chọn số sao');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await UserApi().getCurrentUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để đánh giá');
      }

      final rating = Rating(
        maSanPham: widget.productId,
        maTaiKhoan: user.maTaiKhoan,
        soSao: _selectedStars,
        noiDung: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      bool success;
      if (_userReview != null && _userReview!.soSao > 0) {
        // Update existing review
        success = await RatingApi().updateRating(rating);
      } else {
        // Add new review
        success = await RatingApi().addRating(rating);
      }

      if (success) {
        _showSuccessSnackBar(_userReview != null
            ? 'Cập nhật đánh giá thành công!'
            : 'Gửi đánh giá thành công!');
        await _loadReviews(); // Reload reviews
        setState(() {
          _isEditMode = false;
        });
      } else {
        throw Exception('Không thể gửi đánh giá');
      }
    } catch (e) {
      print('Error submitting review: $e');
      _showErrorSnackBar('Lỗi gửi đánh giá: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xóa đánh giá',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa đánh giá này?',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'HỦY',
                style: TextStyle(color: _textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'XÓA',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        final success = await RatingApi().deleteRating(widget.productId);

        if (success) {
          _showSuccessSnackBar('Xóa đánh giá thành công!');
          await _loadReviews();
        } else {
          throw Exception('Không thể xóa đánh giá');
        }
      } catch (e) {
        print('Error deleting review: $e');
        _showErrorSnackBar('Lỗi xóa đánh giá: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditMode = true;
      if (_userReview != null) {
        _selectedStars = _userReview!.soSao;
        _reviewController.text = _userReview!.noiDung ?? '';
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditMode = false;
      if (_userReview != null) {
        _selectedStars = _userReview!.soSao;
        _reviewController.text = _userReview!.noiDung ?? '';
      } else {
        _selectedStars = 0;
        _reviewController.clear();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildRatingHeader() {
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
          // Overall rating
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
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.productName,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
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
                    _ratingStats?.averageRating.toStringAsFixed(1) ?? '0.0',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  _buildStarRating(_ratingStats?.averageRating ?? 0, size: 20),
                  Text(
                    '${_ratingStats?.totalRatings ?? 0} đánh giá',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User review section
          _buildUserReviewSection(),
        ],
      ),
    );
  }

  Widget _buildUserReviewSection() {
    final hasUserReviewed = _userReview != null && _userReview!.soSao > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasUserReviewed
                    ? Icons.edit_outlined
                    : Icons.rate_review_outlined,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasUserReviewed ? 'Đánh giá của bạn' : 'Viết đánh giá',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              if (hasUserReviewed && !_isEditMode)
                Row(
                  children: [
                    IconButton(
                      onPressed: _startEditing,
                      icon: Icon(Icons.edit, color: _primaryColor, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteReview,
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          if (hasUserReviewed && !_isEditMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStarRating(_userReview!.soSao.toDouble()),
                const SizedBox(width: 8),
                if (_userReview!.noiDung != null &&
                    _userReview!.noiDung!.isNotEmpty)
                  Expanded(
                    child: Text(
                      _userReview!.noiDung!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            // Star rating
            Center(
              child: _buildInteractiveStarRating(),
            ),
            const SizedBox(height: 16),
            // Review text
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                hintStyle: TextStyle(color: _textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: _textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                    : Text(
                        hasUserReviewed ? 'CẬP NHẬT ĐÁNH GIÁ' : 'GỬI ĐÁNH GIÁ'),
              ),
            ),
            if (hasUserReviewed && _isEditMode) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancelEditing,
                  child: Text(
                    'HỦY',
                    style: TextStyle(color: _textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedStars = starIndex;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= _selectedStars ? Icons.star : Icons.star_border,
              color: _starColor,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return Icon(
          starIndex <= rating ? Icons.star : Icons.star_border,
          color: _starColor,
          size: size,
        );
      }),
    );
  }

  Widget _buildReviewsList() {
    // Filter out current user's review from the list
    final otherReviews = _reviews
        .where((review) => review.maTaiKhoan != _userReview?.maTaiKhoan)
        .toList();

    if (otherReviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.reviews_outlined,
              color: _textSecondary.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào từ người dùng khác',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
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
              color: _textPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherReviews.length,
          itemBuilder: (context, index) {
            final review = otherReviews[index];
            return _buildReviewItem(review);
          },
        ),
      ],
    );
  }

  Widget _buildReviewItem(Rating review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
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
              // User avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: _primaryColor,
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
                        color: _textPrimary,
                      ),
                    ),
                    _buildStarRating(review.soSao.toDouble(), size: 14),
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
                color: _textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRatingHeader(),
                    const SizedBox(height: 24),
                    _buildReviewsList(),
                  ],
                ),
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
