import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class GoalIconPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const GoalIconPicker({super.key, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select Icon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                onEmojiSelected(emoji.emoji);
                Navigator.pop(context);
              },
              config: const Config(),
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, Function(String) onEmojiSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GoalIconPicker(onEmojiSelected: onEmojiSelected),
    );
  }
}
