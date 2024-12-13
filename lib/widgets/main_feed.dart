import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/utils/pow.dart';
import 'package:wherostr_social/widgets/feed_menu.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_item.dart';

class MainFeed extends StatefulWidget {
  const MainFeed({
    super.key,
  });

  @override
  State createState() => MainFeedState();
}

class MainFeedState extends State<MainFeed> {
  List<String>? _authors;
  late List<int> _kinds;
  List<String>? _t;
  late bool _includeReplies;
  GlobalKey<NostrFeedState> nostrFeedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    final appFeed = context.read<AppFeedProvider>();

    _handleChange(appFeed.feedFilters);
  }

  void _handleChange(FeedFilters feedFilters) {
    final appState = context.read<AppStatesProvider>();
    final me = appState.me;
    List<String>? authors;
    final kinds = [
      1,
      if (feedFilters.articlesSelected) ...[30023],
      if (feedFilters.liveActivitiesSelected) ...[30311],
      if (feedFilters.repostsSelected) ...[6, 16],
    ];
    final List<String> tags = me.interestSets
        .where((item) => feedFilters.selectedFollowingHashtags.contains(item))
        .toList();
    if (feedFilters.selectedFollowingSets.isNotEmpty) {
      authors = [];
      for (var item in me.followSets) {
        if (feedFilters.selectedFollowingSets.contains(item.id)) {
          authors.addAll(item.value);
        }
      }
    }
    if (feedFilters.followingSelected) {
      final followingAuthors = [me.pubkey, ...me.following];
      if (authors != null) {
        authors = List<String>.from(
            Set.from(authors).intersection(Set.from(followingAuthors)));
      } else {
        authors = followingAuthors;
      }
    }
    setState(() {
      _authors = (authors ?? []).isNotEmpty ? authors : null;
      _kinds = kinds;
      _t = tags.isNotEmpty ? tags : null;
      _includeReplies = feedFilters.repliesSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final powFilter = context.watch<AppFeedProvider>().powPostFilter;
    final difficulty = powFilter.enabled == true ? powFilter.value : null;
    final relayList = context.read<AppStatesProvider>().me.relayList.clone();
    ThemeData themeData = Theme.of(context);
    return NestedScrollView(
      floatHeaderSlivers: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: themeData.colorScheme.surfaceDim,
            floating: true,
            snap: true,
            forceElevated: innerBoxIsScrolled,
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: FeedFilterMenu(
                onChange: _handleChange,
              ),
            ),
          ),
        ];
      },
      body: Builder(
        builder: (context) {
          final scrollController = PrimaryScrollController.of(context);
          return NostrFeed(
            key: nostrFeedKey,
            scrollController: scrollController,
            kinds: _kinds,
            authors: _authors,
            relays: relayList,
            ids: difficulty != null && difficulty > 0
                ? [difficultyToHex(difficulty, true)]
                : null,
            t: _t,
            isDynamicHeight: true,
            includeReplies: _includeReplies,
            itemBuilder: (context, event) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(12),
                ),
                child: PostItem(
                  event: event,
                  enableReplyLabel: _includeReplies,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
