import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_details.dart';

class PostArticle extends StatefulWidget {
  final DataEvent event;

  const PostArticle({
    super.key,
    required this.event,
  });

  @override
  State createState() => _PostArticleState();
}

class _PostArticleState extends State<PostArticle> {
  void openArticle() {
    context.read<AppStatesProvider>().navigatorPush(
          widget: PostDetails(
            event: widget.event,
          ),
        );
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null)
          InkWell(
            onTap: openArticle,
            child: FadeInImage(
              placeholder: MemoryImage(kTransparentImage),
              image: AppUtils.getImageProvider(image),
              fadeInDuration: const Duration(milliseconds: 300),
              fadeInCurve: Curves.easeInOutCubic,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 4),
        if (title != null)
          InkWell(
            onTap: openArticle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: themeData.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                FilledButton.icon(
                  onPressed: openArticle,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Read'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
