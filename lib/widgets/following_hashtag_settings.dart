import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class FollowingHashtagSettings extends StatefulWidget {
  const FollowingHashtagSettings({super.key});

  @override
  State<FollowingHashtagSettings> createState() =>
      _FollowingHashtagSettingsState();
}

class _FollowingHashtagSettingsState extends State<FollowingHashtagSettings> {
  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStatesProvider>();
    final interestSets = appState.me.interestSets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following hashtags'),
      ),
      body: interestSets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No items'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: interestSets.length,
              itemBuilder: (context, index) => Padding(
                key: Key(interestSets[index]),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    HashtagListTile(
                      hashtag: interestSets[index],
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
    );
  }
}

class HashtagListTile extends StatefulWidget {
  final String hashtag;

  const HashtagListTile({
    super.key,
    required this.hashtag,
  });

  @override
  State<HashtagListTile> createState() => _HashtagListTileState();
}

class _HashtagListTileState extends State<HashtagListTile> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    _isFollowing = context
        .read<AppStatesProvider>()
        .me
        .interestSets
        .contains(widget.hashtag);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final appState = context.watch<AppStatesProvider>();
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      minTileHeight: 64,
      horizontalTitleGap: 8,
      leading: Icon(
        Icons.tag,
        color: themeData.colorScheme.secondary,
      ),
      title: Text(
        widget.hashtag,
        style: themeData.textTheme.titleMedium,
      ),
      trailing: Transform.translate(
        offset: const Offset(4, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isFollowing
                ? OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            try {
                              setState(() {
                                _isLoading = true;
                              });
                              await appState.me.unFollowHashtag(widget.hashtag);
                              setState(() {
                                _isFollowing = false;
                              });
                            } catch (error) {
                              AppUtils.handleError();
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    child: Text(
                      'Unfollow',
                      style: TextStyle(color: themeData.colorScheme.error),
                    ),
                  )
                : OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            try {
                              setState(() {
                                _isLoading = true;
                              });
                              await appState.me.followHashtag(widget.hashtag);
                              setState(() {
                                _isFollowing = true;
                              });
                            } catch (error) {
                              AppUtils.handleError();
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    child: const Text('Follow'),
                  ),
          ],
        ),
      ),
    );
  }
}
