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
    final color = isUpvote ? const Color(0xFF63D69A) : const Color(0xFFFF7373);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        foregroundColor: color,
        backgroundColor: selected ? color.withValues(alpha: 0.22) : const Color(0xFF242A31),
        side: BorderSide(
          color: selected ? color : color.withValues(alpha: 0.65),
          width: selected ? 2 : 1,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      icon: Icon(isUpvote ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 30),
    );
  }
}
