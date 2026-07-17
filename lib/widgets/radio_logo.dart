import 'package:flutter/material.dart';

/// Shared Radio Charu logo for use across the app.
class RadioLogo extends StatelessWidget {
  const RadioLogo({
    super.key,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(3),
    this.backgroundColor = Colors.white,
  });

  static const String assetPath = 'Assets/Icon/radio-charu.png';

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
