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

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
      ),
      icon: Icon(
        isUpvote ? Icons.arrow_upward : Icons.arrow_downward,
        size: 28,
        color: selected ? selectedColor : const Color(0xFFB4BDC9),
      ),
    );
  }
}
