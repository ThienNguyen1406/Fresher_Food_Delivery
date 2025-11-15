import 'package:flutter/material.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_stats_widget.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_action_button.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/widgets/rating_list_widget.dart';

class RatingSection extends StatelessWidget {
  final ProductDetailProvider provider;

  const RatingSection({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      icon: Icons.reviews_outlined,
      title: "Đánh giá khách hàng (${provider.ratingStats.totalRatings})",
      child: Column(
        children: [
          RatingStatsWidget(provider: provider),
          const SizedBox(height: 16),
          RatingActionButton(provider: provider),
          const SizedBox(height: 16),
          RatingListWidget(provider: provider),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

