import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';

class RatingStatsWidget extends StatelessWidget {
  final ProductDetailProvider provider;

  const RatingStatsWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  provider.ratingStats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const Text(
                  'Điểm trung bình',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  provider.ratingStats.totalRatings.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Lượt đánh giá',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

