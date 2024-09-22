import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_item.dart';

class HashtagSearch extends StatefulWidget {
  final String hashtag;

  const HashtagSearch({
    super.key,
    required this.hashtag,
  });

  @override
  State<HashtagSearch> createState() => _HashtagSearchState();
}

class _HashtagSearchState extends State<HashtagSearch> {
  late String _hashtag;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    _hashtag = widget.hashtag.trim();
    final me = context.read<AppStatesProvider>().me;
    _isFollowing = me.interestSets
        .map((item) => item.toLowerCase())
        .contains(_hashtag.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final appState = context.watch<AppStatesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('#$_hashtag'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isFollowing
                ? OutlinedButton(
                    onPressed: () async {
                      await appState.me.unFollowHashtag(_hashtag);
                      setState(() {
                        _isFollowing = false;
                      });
                    },
                    child: Text(
                      'Unfollow',
                      style: TextStyle(color: themeData.colorScheme.error),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () async {
                      await appState.me.followHashtag(_hashtag);
                      setState(() {
                        _isFollowing = true;
                      });
                    },
                    child: const Text('Follow'),
                  ),
          ),
        ],
      ),
      body: NostrFeed(
        relays: appState.me.relayList.clone(),
        kinds: const [1],
        t: [_hashtag.toLowerCase()],
        isDynamicHeight: true,
        itemBuilder: (context, item) => Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(12),
            ),
            child: PostItem(event: item),
          ),
        ),
      ),
    );
  }
}
