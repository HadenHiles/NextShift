import 'package:flutter/material.dart';

class PlatformBadge extends StatelessWidget {
  const PlatformBadge({
    super.key,
    required this.platform,
    this.onTap,
  });

  final String platform;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (platform) {
      'The Pond' => (Icons.water, 'THE POND'),
      'How To Hockey' => (Icons.sports_hockey, 'HOW TO HOCKEY'),
      '10,000 Shots App' => (Icons.track_changes, '10K SHOTS'),
      _ => (Icons.apps, platform.toUpperCase()),
    };

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFADB5C0)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDDE1E7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return Tooltip(
      message: platform,
      child: SizedBox(
        width: 112,
        height: 32,
        child: Material(
          color: const Color(0xFF20242A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFF343A43)),
          ),
          clipBehavior: Clip.antiAlias,
          child: onTap == null ? Center(child: child) : InkWell(onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}
