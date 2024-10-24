import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wherostr_social/extension/multi_image_savable_provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/widgets/hashtag_search.dart';
import 'package:wherostr_social/widgets/markdown_content.dart';
import 'package:wherostr_social/widgets/post_action_bar.dart';
import 'package:wherostr_social/widgets/post_composer.dart';

class Article extends StatefulWidget {
  final DataEvent event;

  const Article({
    super.key,
    required this.event,
  });

  @override
  State<Article> createState() => _ArticleState();
}

class _ArticleState extends State<Article> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final tags = widget.event.getTagValues('t');
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PostComposer(
            event: widget.event,
          ),
        ),
        if (image != null)
          InkWell(
            onTap: () => showImageViewerPager(
              context,
              MultiImageSavableProvider(
                [AppUtils.getImageProvider(image)],
                imageUrl: image,
                initialIndex: 0,
              ),
              useSafeArea: true,
              swipeDismissible: true,
              doubleTapZoomable: true,
            ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: themeData.colorScheme.surfaceDim,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                ),
              ),
            ),
          ),
        ],
        if (tags != null && tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 4,
              children: tags
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: () =>
                              context.read<AppStatesProvider>().navigatorPush(
                                    widget: HashtagSearch(
                                      hashtag: item,
                                    ),
                                  ),
                          child: Container(
                            color: themeData.colorScheme.surfaceDim,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Text(
                              '#$item',
                              style: TextStyle(
                                  color: themeData.colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MarkdownContent(
            content: widget.event.content?.trim() ?? '',
            customEmojiTags: widget.event.getMatchedTags('emoji'),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PostActionBar(
            event: widget.event,
          ),
        ),
      ],
    );
  }
}
