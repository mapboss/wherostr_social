import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/utils/pow.dart';
import 'package:wherostr_social/widgets/post_article.dart';
import 'package:wherostr_social/widgets/post_details.dart';
import 'package:wherostr_social/widgets/post_live_activity.dart';
import 'package:wherostr_social/widgets/post_unsupported_type.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/post_action_bar.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_content.dart';
import 'package:wherostr_social/widgets/post_item_loader.dart';
import 'package:wherostr_social/widgets/post_location_chip.dart';
import 'package:wherostr_social/widgets/post_proof_of_work_chip.dart';
import 'package:wherostr_social/widgets/resize_observer.dart';

class PostItem extends StatelessWidget {
  final NostrEvent event;
  final bool enableShowProfileAction;
  final bool enableMenu;
  final bool enableTap;
  final bool enableElementTap;
  final bool enableActionBar;
  final bool enableLocation;
  final bool enableProofOfWork;
  final bool enablePreview;
  final EdgeInsetsGeometry? contentPadding;
  final int depth;
  final double? maxHeight;

  const PostItem({
    super.key,
    required this.event,
    this.enableShowProfileAction = true,
    this.enableMenu = true,
    this.enableTap = true,
    this.enableElementTap = true,
    this.enableActionBar = true,
    this.enableLocation = true,
    this.enableProofOfWork = true,
    this.enablePreview = true,
    this.contentPadding,
    this.depth = 0,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget? widget;
    switch (event.kind) {
      case 1:
        widget = ShortTextNote(
          event: event,
          enableShowProfileAction: enableShowProfileAction,
          enableMenu: enableMenu,
          enableTap: enableTap,
          enableElementTap: enableElementTap,
          enableActionBar: enableActionBar,
          enableLocation: enableLocation,
          enableProofOfWork: enableProofOfWork,
          enablePreview: enablePreview,
          contentPadding: contentPadding,
          depth: depth,
        );
        if ((maxHeight ?? 0) > 0) {
          widget = LimitedBox(
            maxHeight: maxHeight!,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: widget,
            ),
          );
        }
        break;
      case 6:
        widget = Repost(
          event: event,
          enableShowProfileAction: enableShowProfileAction,
          enableMenu: enableMenu,
          enableActionBar: enableActionBar,
          enableLocation: enableLocation,
          enableProofOfWork: enableProofOfWork,
          enablePreview: enablePreview,
          contentPadding: contentPadding,
          depth: depth,
        );
        break;
      case 30311:
        widget = PostLiveActivity(
          event: event,
        );
        break;
      case 30023:
        widget = PostArticle(
          event: event,
        );
        break;
      default:
        widget = const PostUnsupportedType();
    }
    return Material(
      child: widget,
    );
  }
}

class PostContentWrapper extends StatefulWidget {
  final NostrEvent event;
  final Widget child;
  final VoidCallback? onShowMorePressed;

  const PostContentWrapper({
    super.key,
    required this.event,
    required this.child,
    this.onShowMorePressed,
  });

  @override
  State<PostContentWrapper> createState() => _PostContentWrapperState();
}

final Map<String, bool> postContentExceededMaxHeight = {};

class _PostContentWrapperState extends State<PostContentWrapper> {
  bool _exceededMaxHeight = false;

  @override
  void initState() {
    super.initState();
    _exceededMaxHeight = postContentExceededMaxHeight[widget.event.id] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    double maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    if (maxHeight < 200) {
      maxHeight = 200;
    }
    return _exceededMaxHeight
        ? Stack(
            alignment: Alignment.bottomCenter,
            children: [
              LimitedBox(
                maxHeight: maxHeight,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: widget.child,
                ),
              ),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      themeData.colorScheme.surface,
                      themeData.colorScheme.surface.withOpacity(0),
                    ],
                  ),
                ),
              ),
              FilledButton(
                onPressed: widget.onShowMorePressed,
                child: const Text('Show more'),
              ),
            ],
          )
        : ResizeObserver(
            onResized: (Size? oldSize, Size newSize) {
              if (!_exceededMaxHeight && newSize.height > maxHeight) {
                postContentExceededMaxHeight[widget.event.id!] = true;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => setState(() {
                          _exceededMaxHeight = true;
                        }));
              }
            },
            child: widget.child,
          );
  }
}

class ShortTextNote extends PostItem {
  const ShortTextNote({
    super.key,
    required super.event,
    super.enableShowProfileAction = true,
    super.enableMenu = true,
    super.enableTap = true,
    super.enableElementTap = true,
    super.enableActionBar = true,
    super.enableLocation = true,
    super.enableProofOfWork = true,
    super.enablePreview = true,
    super.contentPadding,
    super.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStatesProvider>();
    final postContentWidget = Padding(
      padding: contentPadding ?? const EdgeInsets.all(0),
      child: PostContent(
        content: event.content?.trim() ?? '',
        enableElementTap: enableElementTap,
        enablePreview: enablePreview,
        depth: depth,
      ),
    );
    return InkWell(
      onTap: enableTap == true
          ? () => appState.navigatorPush(
                widget: PostDetails(
                  event: event,
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostComposer(
              event: event,
              enableShowProfileAction: enableShowProfileAction,
              enableMenu: enableMenu,
            ),
            enableTap == true
                ? PostContentWrapper(
                    event: event,
                    onShowMorePressed: () => appState.navigatorPush(
                      widget: PostDetails(
                        event: event,
                      ),
                    ),
                    child: postContentWidget,
                  )
                : postContentWidget,
            if (enableLocation == true || enableProofOfWork == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (enableLocation == true) PostLocationChip(event: event),
                  if (enableProofOfWork == true)
                    PostProofOfWorkChip(difficulty: getDifficulty(event)),
                ],
              ),
            if (enableActionBar == true) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              PostActionBar(
                event: event,
              ),
            ] else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class Repost extends PostItem {
  const Repost({
    super.key,
    required super.event,
    super.enableShowProfileAction = true,
    super.enableMenu = true,
    super.enableActionBar = true,
    super.enableLocation = true,
    super.enableProofOfWork = true,
    super.enablePreview = true,
    super.contentPadding,
    super.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final String? eventId = event.tags
        ?.where((item) => item.firstOrNull == 'e')
        .firstOrNull
        ?.elementAtOrNull(1);

    DataEvent? repostedEvent;
    try {
      repostedEvent = (event.content == null || event.content!.isEmpty)
          ? null
          : DataEvent.deserialized('["EVENT",null,${event.content}]');
    } catch (err) {
      print('Repost.event: ${event.serialized()} ERROR: $err');
    }
    return eventId == null
        ? const SizedBox.shrink()
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: themeExtension.textDimColor,
                    ),
                    const SizedBox(width: 4),
                    ProfileDisplayName(
                      pubkey: event.pubkey,
                      withBadge: true,
                      enableShowProfileAction: true,
                      textStyle: TextStyle(
                        color: themeExtension.textDimColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'reposted',
                      style: TextStyle(
                        color: themeExtension.textDimColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (repostedEvent == null)
                PostItemLoader(
                  eventId: eventId,
                  enableShowProfileAction: enableShowProfileAction,
                  enableMenu: enableMenu,
                  enableActionBar: enableActionBar,
                  enableLocation: enableLocation,
                  enableProofOfWork: enableProofOfWork,
                  enablePreview: enablePreview,
                  depth: depth,
                )
              else
                PostItem(
                  event: repostedEvent,
                  enableShowProfileAction: enableShowProfileAction,
                  enableMenu: enableMenu,
                  enableActionBar: enableActionBar,
                  enableLocation: enableLocation,
                  enableProofOfWork: enableProofOfWork,
                  enablePreview: enablePreview,
                  contentPadding: contentPadding,
                  depth: depth,
                )
            ],
          );
  }
}
