import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

class ProfileFollowing extends StatefulWidget {
  final NostrUser user;
  final int initialIndex;

  const ProfileFollowing({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State createState() => _ProfileFollowingState();
}

class _ProfileFollowingState extends State<ProfileFollowing> {
  Map<String, bool> events = {};
  List<String>? _following;
  List<String>? _followers;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    events.clear();
    super.dispose();
  }

  void initialize() async {
    widget.user.fetchFollowing().then((value) {
      if (mounted) {
        setState(() {
          _following = value;
        });
      }
    });
    widget.user.fetchFollower().then((value) {
      if (mounted) {
        setState(() {
          _followers = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialIndex,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: ProfileDisplayName(
            user: widget.user,
            withBadge: true,
          ),
          bottom: TabBar(
            onTap: (value) {
              setState(() {
                events.clear();
              });
            },
            tabs: [
              Tab(
                  text:
                      'Following${(_following?.isNotEmpty ?? false) ? ' (${NumberFormat.compact().format(_following!.length)})' : ''}'),
              Tab(
                  text:
                      'Followers${(_followers?.isNotEmpty ?? false) ? ' (${NumberFormat.compact().format(_followers!.length)})' : ''}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _following == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Loading'),
                      ],
                    ),
                  )
                : _following!.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No items'),
                          ],
                        ),
                      )
                    : NostrFeed(
                        disableSubscribe: true,
                        kinds: const [0],
                        authors: _following,
                        limit: 50,
                        itemBuilder: (context, event) {
                          return Padding(
                            key: Key(event.pubkey),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                ProfileListTile(
                                  user: NostrUser.fromEvent(event),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          );
                        },
                      ),
            _followers == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Loading'),
                      ],
                    ),
                  )
                : _followers!.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No items'),
                          ],
                        ),
                      )
                    : NostrFeed(
                        disableSubscribe: true,
                        kinds: const [3],
                        p: [widget.user.pubkey],
                        limit: 50,
                        itemFilter: (e) {
                          if (events.containsKey(e.pubkey)) return false;
                          events[e.pubkey] = true;
                          return true;
                        },
                        itemBuilder: (context, event) {
                          return Padding(
                            key: Key(event.pubkey),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                ProfileListTile(
                                  pubkey: event.pubkey,
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

class ProfileListTile extends StatefulWidget {
  final NostrUser? user;
  final String? pubkey;

  const ProfileListTile({
    super.key,
    this.user,
    this.pubkey,
  });

  @override
  State<ProfileListTile> createState() => _ProfileListTileState();
}

class _ProfileListTileState extends State<ProfileListTile> {
  NostrUser? _user;
  bool _isMe = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    NostrUser? user;
    if (widget.user != null) {
      user = widget.user;
    } else if (widget.pubkey != null) {
      user = await NostrService.fetchUser(widget.pubkey!);
    }
    if (mounted && user != null) {
      setState(() {
        _user = user;
        _isMe = me.pubkey == user!.pubkey;
        _isFollowing = me.following.contains(user.pubkey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    return _user == null
        ? Shimmer.fromColors(
            baseColor: themeExtension.shimmerBaseColor!,
            highlightColor: themeExtension.shimmerHighlightColor!,
            child: ListTile(
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
          )
        : ListTile(
            contentPadding: const EdgeInsets.all(0),
            minTileHeight: 64,
            horizontalTitleGap: 8,
            leading: InkWell(
              onTap: () => appState.navigatorPush(
                widget: Profile(
                  user: _user!,
                ),
              ),
              child: ProfileAvatar(url: _user!.picture),
            ),
            title: ProfileDisplayName(
              user: _user,
              textStyle: themeData.textTheme.titleMedium,
              withBadge: true,
              enableShowProfileAction: true,
            ),
            subtitle: _user!.nip05 == null
                ? null
                : Text(
                    _user!.nip05!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Transform.translate(
              offset: const Offset(4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_user != null && !_isMe) ...[
                    if (_isFollowing) ...[
                      MenuAnchor(
                        builder: (BuildContext context,
                            MenuController controller, Widget? child) {
                          return OutlinedButton(
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            child: const Text('Following'),
                          );
                        },
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () async {
                              await appState.me.unfollow(_user!.pubkey);
                              setState(() {
                                _isFollowing = false;
                              });
                            },
                            leadingIcon: Icon(
                              Icons.person_remove,
                              color: themeData.colorScheme.error,
                            ),
                            child: Text(
                              'Unfollow',
                              style:
                                  TextStyle(color: themeData.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      FilledButton(
                        onPressed: () async {
                          await appState.me.follow(_user!.pubkey);
                          setState(() {
                            _isFollowing = true;
                          });
                        },
                        child: const Text('Follow'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
  }
}
