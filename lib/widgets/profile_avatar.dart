import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class ProfileAvatar extends StatelessWidget {
  final String? url;
  final ImageProvider<Object>? image;
  final double borderSize;

  const ProfileAvatar({
    super.key,
    this.url,
    this.image,
    this.borderSize = 2,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final backgroundImage = image ??
        (url != null ? AppUtils.getCachedImageProvider(url!, 320) : null);
    return Container(
      padding: EdgeInsets.all(borderSize),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeData.colorScheme.secondary,
            Colors.white,
            themeData.colorScheme.primary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: const [0.38, 0.54, 0.87],
        ),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: themeData.colorScheme.surfaceDim,
        backgroundImage: backgroundImage,
        child: backgroundImage == null
            ? SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Icon(
                      Icons.person,
                      color: themeExtension.textDimColor,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
