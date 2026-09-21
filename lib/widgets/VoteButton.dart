import 'package:flutter/material.dart';

class VoteButton extends StatelessWidget {
  const VoteButton({
    super.key,
    required this.isUpvote,
    required this.selected,
    required this.tooltip,
    required this.onPressed,
  });

  final bool isUpvote;
  final bool selected;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isUpvote ? const Color(0xFF63D69A) : const Color(0xFFFF7373);
    final iconColor = selected ? selectedColor : Colors.white;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.square(44)),
        foregroundColor: WidgetStatePropertyAll(iconColor),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      icon: Icon(
        isUpvote ? Icons.arrow_upward : Icons.arrow_downward,
        size: 32,
      ),
    );
  }
}
