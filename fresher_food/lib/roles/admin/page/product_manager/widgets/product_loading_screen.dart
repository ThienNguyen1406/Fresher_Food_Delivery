import 'package:flutter/material.dart';

class ProductLoadingScreen extends StatelessWidget {
  const ProductLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E7D32)),
          SizedBox(height: 16),
          Text('Đang tải sản phẩm...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

