import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppPallete.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No items in inbox',
              style: TextStyle(fontSize: 16, color: AppPallete.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
