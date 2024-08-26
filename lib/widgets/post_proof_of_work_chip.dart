import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_theme.dart';

class PostProofOfWorkChip extends StatelessWidget {
  final int? difficulty;

  const PostProofOfWorkChip({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;

    return difficulty == 0 || difficulty == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.memory,
                  size: themeData.textTheme.labelLarge?.fontSize,
                  color: themeExtension.textDimColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'PoW-$difficulty',
                  style: themeData.textTheme.labelMedium
                      ?.copyWith(color: themeData.colorScheme.primary),
                ),
              ],
            ),
          );
  }
}
