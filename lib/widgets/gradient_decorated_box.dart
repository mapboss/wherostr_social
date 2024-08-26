import 'package:flutter/material.dart';

class GradientDecoratedBox extends StatelessWidget {
  final Widget? child;

  const GradientDecoratedBox({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeData.colorScheme.surface.withOpacity(0.13),
            themeData.colorScheme.primary.withOpacity(0.13),
          ],
        ),
      ),
      child: child,
    );
  }
}
