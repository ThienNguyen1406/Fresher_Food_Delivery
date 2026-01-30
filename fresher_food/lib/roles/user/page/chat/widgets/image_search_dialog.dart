import 'package:flutter/material.dart';
import 'dart:io';

/// Dialog để chọn ảnh và nhập mô tả cho tìm kiếm sản phẩm
class ImageSearchDialog extends StatefulWidget {
  final String imagePath;

  const ImageSearchDialog({super.key, required this.imagePath});

  @override
  State<ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<ImageSearchDialog> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.image, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text('Tìm kiếm sản phẩm bằng ảnh')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hiển thị ảnh preview
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Text field để nhập mô tả
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả về ảnh (tùy chọn)',
                hintText: 'Ví dụ: Tìm sản phẩm tương tự như ảnh này...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _descriptionController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tìm kiếm'),
        ),
      ],
    );
  }
}

