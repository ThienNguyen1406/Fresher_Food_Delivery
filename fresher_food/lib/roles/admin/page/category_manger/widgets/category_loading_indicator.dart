import 'package:flutter/material.dart';

class CategoryLoadingIndicator extends StatelessWidget {
  const CategoryLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1A4D2E)),
          SizedBox(height: 16),
          Text('Đang tải danh mục...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

