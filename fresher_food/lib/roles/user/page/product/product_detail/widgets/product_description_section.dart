import 'package:flutter/material.dart';
import 'package:fresher_food/models/Product.dart';

class ProductDescriptionSection extends StatelessWidget {
  final Product product;

  const ProductDescriptionSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      icon: Icons.description_outlined,
      title: "Mô tả sản phẩm",
      child: Text(
        product.moTa.isNotEmpty
            ? product.moTa
            : "Sản phẩm chất lượng cao, phù hợp cho mọi gia đình. Hương vị tươi ngon và giá trị dinh dưỡng tuyệt vời.",
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
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
