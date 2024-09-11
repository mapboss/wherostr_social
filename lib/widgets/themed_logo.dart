import 'package:flutter/material.dart';

class ThemedLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final bool? textEnabled;

  const ThemedLogo({
    super.key,
    this.height,
    this.width,
    this.textEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: themeData.colorScheme.brightness == Brightness.light
            ? [
                Expanded(
                  child: Image.asset(
                    'assets/app/logo-light.png',
                  ),
                ),
                if (textEnabled == true) ...[
                  Image.asset(
                    'assets/app/logo-name-light.png',
                  ),
                ],
              ]
            : [
                Expanded(
                  child: Image.asset(
                    'assets/app/logo-dark.png',
                  ),
                ),
                if (textEnabled == true) ...[
                  Image.asset(
                    'assets/app/logo-name-dark.png',
                  ),
                ],
              ],
      ),
    );
  }
}
