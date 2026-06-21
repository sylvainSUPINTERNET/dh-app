import 'package:flutter/material.dart';

class AbstractBackground extends StatelessWidget {
  final Widget child;

  const AbstractBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEDC4B8),
            Color(0xFFFAF0E8),
          ],
          stops: [0.0, 0.35],
        ),
      ),
      child: child,
    );
  }
}
