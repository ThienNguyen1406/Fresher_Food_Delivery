import 'package:flutter/material.dart';
import 'package:fresher_food/models/Rating.dart';
import 'package:fresher_food/roles/user/page/product/product_detail/provider/product_detail_provider.dart';

class RatingItemWidget extends StatelessWidget {
  final Rating rating;
  final ProductDetailProvider provider;

  const RatingItemWidget({
    super.key,
    required this.rating,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = provider.userRating?.maTaiKhoan == rating.maTaiKhoan;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade200,
          child: Text(
            rating.maTaiKhoan.characters.first.toUpperCase(),
            style: TextStyle(
              color: isCurrentUser ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            for (int i = 0; i < 5; i++)
              Icon(
                i < rating.soSao ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            const SizedBox(width: 8),
            Text('${rating.soSao}/5'),
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rating.noiDung != null && rating.noiDung!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  rating.noiDung!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Người dùng: ${rating.maTaiKhoan}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
