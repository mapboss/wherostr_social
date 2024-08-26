import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_activity.dart';
import 'package:wherostr_social/widgets/post_compose.dart';
import 'package:wherostr_social/widgets/post_item.dart';

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

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    DataEvent? event;
    if (widget.event != null) {
      event = widget.event;
    } else if (widget.eventId != null) {
      event = await NostrService.fetchEventById(widget.eventId!);
    }
    if (mounted && event != null) {
      setState(() {
        _event = event;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      bottomNavigationBar: _event == null
          ? null
          : Material(
              elevation: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          PostItem(
                            event: _event!,
                            enableTap: false,
                          ),
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
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Builder(builder: (context) {
                final scrollController = PrimaryScrollController.of(context);
                return NostrFeed(
                  relays: appState.me.relayList.clone(),
                  scrollController: scrollController,
                  kinds: const [1],
                  e: [_event!.id!],
                  includeReplies: true,
                  autoRefresh: true,
                  isAscending: true,
                  itemFilter: (itemEvent) {
                    return isReply(
                      event: itemEvent,
                      referenceEventId: _event!.id,
                      isDirectOnly: true,
                    );
                  },
                  itemBuilder: (context, event) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: PostItem(
                      event: event,
                      contentPadding: const EdgeInsets.only(left: 54),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}
