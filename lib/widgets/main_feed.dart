import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/feed_menu_item.dart';
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
  List<String>? _t;
  GlobalKey<NostrFeedState> nostrFeedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() {
    final appFeed = context.read<AppFeedProvider>();
    _handleChange(appFeed.selectedItem);
  }

  void _handleChange(FeedMenuItem item) {
    if (item.id == 'following') {
      final me = context.read<AppStatesProvider>().me;
      setState(() {
        _authors = [me.pubkey, if (me.following.isNotEmpty) ...me.following];
        _t = null;
      });
    } else if (item.type == 'tag') {
      setState(() {
        _authors = null;
        _t = item.value;
      });
    } else if (item.type == 'list') {
      setState(() {
        _authors = item.value;
        _t = null;
      });
    } else if (item.id == 'global') {
      setState(() {
        _authors = null;
        _t = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
            kinds: const [1, 6],
            authors: _authors,
            relays: relayList,
            t: _t,
            itemBuilder: (context, item) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(12),
                ),
                child: PostItem(event: item),
              ),
            ),
          );
        },
      ),
    );
  }
}
