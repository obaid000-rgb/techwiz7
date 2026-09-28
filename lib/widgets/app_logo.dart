import 'package:flutter/material.dart';

/// The Fandom Verse logo (the rounded app-icon tile), used everywhere the
/// app shows its brand. Sizes: small 32 (top bar), medium 64 (auth, About
/// Us, admin header), large 120 (splash); any other size is allowed.
class AppLogo extends StatelessWidget {
  static const asset = 'assets/icon/fandom_verse_icon_1024.png';

  final double size;
  const AppLogo({super.key, this.size = 64});
  const AppLogo.small({super.key}) : size = 32;
  const AppLogo.medium({super.key}) : size = 64;
  const AppLogo.large({super.key}) : size = 120;

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      asset,
      width: size,
      height: size,
      // Decode at display size, not 1024 px, to keep memory low.
      cacheWidth: px,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Fandom Verse',
    );
  }
}
