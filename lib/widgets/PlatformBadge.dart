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
    final child = switch (platform) {
      'The Pond' => Image.asset(
          'assets/images/logos/thepond_rgb.png',
          height: 30,
        ),
      'How To Hockey' => Image.asset(
          'assets/images/logos/hth_logo.png',
          height: 35,
        ),
      '10,000 Shots App' => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_hockey, size: 24),
            Text('10K Shots', style: TextStyle(fontSize: 11)),
          ],
        ),
      _ => Text(platform, textAlign: TextAlign.center),
    };

    return Tooltip(
      message: platform,
      child: SizedBox(
        width: 82,
        height: 56,
        child: onTap == null
            ? Center(child: child)
            : InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onTap,
                child: Center(child: child),
              ),
      ),
    );
  }
}
