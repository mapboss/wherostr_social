import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/widgets/post_composer.dart';

class PostArticle extends StatefulWidget {
  final NostrEvent event;

  const PostArticle({
    super.key,
    required this.event,
  });

  @override
  State createState() => _PostArticleState();
}

class _PostArticleState extends State<PostArticle> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final image = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'image')
        .firstOrNull
        ?.elementAtOrNull(1);
    final title = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'title')
        .firstOrNull
        ?.elementAtOrNull(1);
    final publishedAt = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'published_at')
        .firstOrNull
        ?.elementAtOrNull(1);
    final publishedAtDateTime = publishedAt == null
        ? widget.event.createdAt!
        : DateTime.fromMillisecondsSinceEpoch(int.parse(publishedAt) * 1000);
    final summary = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'summary')
        .firstOrNull
        ?.elementAtOrNull(1);
    final postNostrAddress = getNostrAddress(widget.event);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null)
          FadeInImage(
            placeholder: MemoryImage(kTransparentImage),
            image: AppUtils.getImageProvider(image),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeInCurve: Curves.easeInOutCubic,
            fit: BoxFit.cover,
          ),
        const SizedBox(height: 8),
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: themeData.textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Published ${formatTimeAgo(publishedAtDateTime)}',
            style: themeData.textTheme.bodySmall!
                .apply(color: themeExtension.textDimColor),
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Summary: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeExtension.textDimColor,
                    ),
                  ),
                  TextSpan(
                    text: summary,
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PostComposer(
            event: widget.event,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MenuAnchor(
                  builder: (BuildContext context, MenuController controller,
                      Widget? child) {
                    return FilledButton.icon(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Read'),
                    );
                  },
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => launchUrl(
                          Uri.parse('https://habla.news/a/$postNostrAddress')),
                      leadingIcon: FadeInImage(
                        width: 40,
                        height: 40,
                        placeholder: MemoryImage(kTransparentImage),
                        image: AppUtils.getImageProvider(
                            'https://habla.news/favicon.png'),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeInCurve: Curves.easeInOutCubic,
                        fit: BoxFit.contain,
                      ),
                      child: const Text('Habla'),
                    ),
                    MenuItemButton(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://yakihonne.com/article/$postNostrAddress')),
                      leadingIcon: FadeInImage(
                        width: 40,
                        height: 40,
                        placeholder: MemoryImage(kTransparentImage),
                        image: AppUtils.getImageProvider(
                            'https://yakihonne.com/favicon.ico'),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeInCurve: Curves.easeInOutCubic,
                        fit: BoxFit.contain,
                      ),
                      child: const Text('Yakihonne'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
