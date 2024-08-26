import 'package:flutter/material.dart';

class ThemedLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final bool? textEnabled;
  const ThemedLogo(
      {super.key, this.height, this.width, this.textEnabled = false});

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Column(
      children: themeData.colorScheme.brightness == Brightness.light
          ? [
              Image.asset(
                'assets/app/logo-light.png',
                width: width,
                height: height,
              ),
              if (textEnabled == true) ...[
                Image.asset(
                  'assets/app/logo-name-light.png',
                  width: width,
                  height: height,
                ),
              ],
            ]
          : [
              Image.asset(
                'assets/app/logo-dark.png',
                width: width,
                height: height,
              ),
              if (textEnabled == true) ...[
                Image.asset(
                  'assets/app/logo-name-dark.png',
                  width: width,
                  height: height,
                ),
              ],
            ],
    );
  }
}
