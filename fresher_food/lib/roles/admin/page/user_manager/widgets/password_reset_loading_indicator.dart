import 'package:flutter/material.dart';

class PasswordResetLoadingIndicator extends StatelessWidget {
  const PasswordResetLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

