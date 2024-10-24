import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/utils/pow.dart';
import 'package:wherostr_social/widgets/article.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_activity.dart';
import 'package:wherostr_social/widgets/post_compose.dart';
import 'package:wherostr_social/widgets/post_item.dart';
import 'package:wherostr_social/widgets/resize_observer.dart';

class PostDetails extends StatefulWidget {
  final DataEvent? event;
  final String? eventId;

  const PostDetails({
    super.key,
    this.event,
    this.eventId,
  });

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  DataEvent? _event;
  DataEvent? _parentEvent;
  late ScrollController _scrollController;
  bool _isScrollReverse = false;
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    try {
      final me = context.read<AppStatesProvider>().me;
      DataEvent? event;
      if (widget.event != null) {
        event = widget.event;
      } else if (widget.eventId != null) {
        event = await NostrService.fetchEventById(
          widget.eventId!,
          relays: me.relayList,
        );
      }
      DataEvent? parentEvent;
      if (event != null) {
        final parentEventId = getParentEventId(event: event);
        if (parentEventId != null) {
          try {
            parentEvent = await NostrService.fetchEventById(
              parentEventId,
              relays: me.relayList,
            );
          } catch (error) {}
        }
      }
      if (mounted && event != null) {
        setState(() {
          _event = event;
          _parentEvent = parentEvent;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _scrollController = PrimaryScrollController.of(context);
          _scrollController.addListener(scrollControllerListener);
        });
      });
    } catch (error) {}
  }

  void scrollControllerListener() {
    if (_scrollController.position.atEdge) {
      setState(() {
        _isScrollReverse = false;
      });
    } else if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      setState(() {
        _isScrollReverse = _scrollController.position.userScrollDirection ==
            ScrollDirection.reverse;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeDisplay =
        MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth;
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final powFilter = context.watch<AppFeedProvider>().powCommentFilter;
    final difficulty = powFilter.enabled == true ? powFilter.value : null;
    final appState = context.watch<AppStatesProvider>();
    final scrollController = PrimaryScrollController.of(context);
    Widget? postWidget;
    if (_event != null) {
      switch (_event!.kind) {
        case 30023:
          postWidget = Material(
            child: Article(
              event: _event!,
            ),
          );
        default:
          postWidget = PostItem(
            event: _event!,
            enableTap: false,
          );
      }
    }
    final homeScaffoldKey = AppStatesProvider.homeScaffoldKey;
    final topPadding =
        MediaQuery.of(homeScaffoldKey.currentContext!).viewPadding.top;
    final eventId = widget.event?.getAddressId();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, topPadding + kToolbarHeight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: topPadding + (_isScrollReverse ? 0 : kToolbarHeight),
          child: AppBar(
            flexibleSpace: GestureDetector(
              onTap: () => AppUtils.scrollToTop(context),
            ),
            title: GestureDetector(
              onTap: () => AppUtils.scrollToTop(context),
              child: const Text('Post'),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _event == null
          ? null
          : AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isScrollReverse ? 0 : 64,
              child: SingleChildScrollView(
                controller: ScrollController(),
                physics: const NeverScrollableScrollPhysics(),
                child: Material(
                  borderRadius: isLargeDisplay
                      ? const BorderRadiusDirectional.vertical(
                          top: Radius.circular(12),
                        )
                      : null,
                  elevation: 1,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          isDense: true,
                          filled: true,
                          fillColor: themeData.colorScheme.surfaceDim,
                          prefixIcon: const Icon(Icons.comment_outlined),
                          hintText: 'Add a reply',
                        ),
                        readOnly: true,
                        onTap: () => appState.navigatorPush(
                          widget: PostCompose(
                            referencedEvent: _event,
                            isReply: true,
                          ),
                          rootNavigator: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: _event == null
          ? Shimmer.fromColors(
              baseColor: themeExtension.shimmerBaseColor!,
              highlightColor: themeExtension.shimmerHighlightColor!,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          minTileHeight: 64.0,
                          horizontalTitleGap: 8,
                          leading: const CircleAvatar(),
                          title: Container(
                            height: 16,
                            color: Colors.white,
                          ),
                          subtitle: Container(
                            height: 12,
                            color: Colors.white,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (_parentEvent != null)
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              foregroundDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: themeData.colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  ResizeObserver(
                                    onResized: (Size? oldSize, Size newSize) {
                                      if (scrollController.offset <
                                          newSize.height) {
                                        _debouncer.debounce(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          onDebounce: () {
                                            scrollController.animateTo(
                                              newSize.height,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOutCubic,
                                            );
                                          },
                                        );
                                      }
                                    },
                                    child: PostItem(
                                      event: _parentEvent!,
                                      contentPadding:
                                          const EdgeInsets.only(left: 54),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.reply,
                                          size: 16,
                                          color: themeExtension.textDimColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Replied to',
                                          style: TextStyle(
                                              color:
                                                  themeExtension.textDimColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        postWidget!,
                      ],
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Replies',
                          style: themeData.textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: () => appState.navigatorPush(
                            widget: PostActivity(
                              event: _event!,
                            ),
                          ),
                          label: const Text('View activity'),
                          icon: const Icon(Icons.navigate_next),
                          iconAlignment: IconAlignment.end,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: NostrFeed(
                      relays: appState.me.relayList.clone(),
                      scrollController: scrollController,
                      kinds: const [1],
                      e: eventId == null ? [_event!.id!] : null,
                      a: eventId == null ? null : [eventId],
                      ids: difficulty != null && difficulty > 0
                          ? [difficultyToHex(difficulty, true)]
                          : null,
                      disablePullToRefresh: true,
                      includeReplies: true,
                      autoRefresh: true,
                      isAscending: true,
                      isDynamicHeight: true,
                      itemFilter: (itemEvent) {
                        return isReply(
                          event: itemEvent,
                          referenceEventId: eventId ?? _event!.id,
                          isDirectOnly: true,
                        );
                      },
                      itemBuilder: (context, event) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: PostItem(
                            event: event,
                            contentPadding: const EdgeInsets.only(left: 54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
