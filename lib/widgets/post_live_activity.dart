import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/widgets/live_activity.dart';
import 'package:wherostr_social/widgets/post_composer.dart';

class PostLiveActivity extends StatefulWidget {
  final DataEvent event;

  const PostLiveActivity({
    super.key,
    required this.event,
  });

  @override
  State createState() => _PostLiveActivityState();
}

class _PostLiveActivityState extends State<PostLiveActivity> {
  void openLiveActivity() {
    context.read<AppStatesProvider>().navigatorPush(
          widget: LiveActivity(
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
    final isLive = widget.event.tags
            ?.where((tag) => tag.firstOrNull == 'status')
            .firstOrNull
            ?.elementAtOrNull(1) ==
        'live';
    final starts = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'starts')
        .firstOrNull
        ?.elementAtOrNull(1);
    final ends = widget.event.tags
        ?.where((tag) => tag.firstOrNull == 'ends')
        .firstOrNull
        ?.elementAtOrNull(1);
    final startDateTime = starts == null
        ? widget.event.createdAt!
        : DateTime.fromMillisecondsSinceEpoch(int.parse(starts) * 1000);
    final endDateTime = ends == null
        ? widget.event.createdAt!
        : DateTime.fromMillisecondsSinceEpoch(int.parse(ends) * 1000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null)
          InkWell(
            onTap: openLiveActivity,
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
            onTap: openLiveActivity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: themeData.textTheme.titleMedium,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isLive
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.red,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 10,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatTimeAgo(startDateTime),
                      style: themeData.textTheme.bodySmall!
                          .apply(color: themeExtension.textDimColor),
                    ),
                  ],
                )
              : Text(
                  '${isLive ? null : 'Streamed '}${formatTimeAgo(endDateTime)}',
                  style: themeData.textTheme.bodySmall!
                      .apply(color: themeExtension.textDimColor),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PostComposer(
            event: widget.event,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: openLiveActivity,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Watch'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
