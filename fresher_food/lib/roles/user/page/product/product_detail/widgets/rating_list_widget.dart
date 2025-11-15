import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_item_widget.dart';

class RatingListWidget extends StatelessWidget {
  final ProductDetailProvider provider;

  const RatingListWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.ratings.isEmpty) {
      return const Column(
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên đánh giá sản phẩm này',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: provider.ratings
          .map((rating) => RatingItemWidget(
                rating: rating,
                provider: provider,
              ))
          .toList(),
    );
  }
}
