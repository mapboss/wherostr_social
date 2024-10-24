import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/extension/multi_image_savable_provider.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class MarkdownContent extends StatefulWidget {
  final String content;
  final List<List<String>>? customEmojiTags;
  final bool enableElementTap;

  const MarkdownContent({
    super.key,
    required this.content,
    this.customEmojiTags,
    this.enableElementTap = true,
  });

  @override
  State createState() => _MarkdownContentState();
}

class _MarkdownContentState extends State<MarkdownContent> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Markdown(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      controller: ScrollController(),
      physics: const NeverScrollableScrollPhysics(),
      selectable: true,
      data: widget.content,
      onTapLink: (text, href, _) => launchUrl(Uri.parse(href ?? text)),
      imageBuilder: (uri, title, alt) {
        final imageProvider = AppUtils.getImageProvider(uri.toString());
        return InkWell(
          onTap: () => showImageViewerPager(
            context,
            MultiImageSavableProvider(
              [imageProvider],
              imageUrl: uri.toString(),
              initialIndex: 0,
            ),
            useSafeArea: true,
            swipeDismissible: true,
            doubleTapZoomable: true,
          ),
          child: Image(
            image: imageProvider,
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        a: TextStyle(color: themeData.colorScheme.primary),
        codeblockPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        codeblockDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: themeData.colorScheme.surfaceDim,
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: themeData.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
      ),
    );
  }
}
