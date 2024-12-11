import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';

class FeedFilterMenu extends StatefulWidget {
  final ValueChanged<FeedFilters>? onChange;
  const FeedFilterMenu({super.key, this.onChange});

  @override
  State createState() => _FeedFilterMenuState();
}

class _FeedFilterMenuState extends State<FeedFilterMenu> {
  late bool _followingSelected;
  late bool _articlesSelected;
  late bool _liveActivitiesSelected;
  late bool _repliesSelected;
  late bool _repostsSelected;
  late List<FollowSet> _selectedFollowingSets;
  late List<String> _selectedFollowingHashtags;

  @override
  void initState() {
    super.initState();
    final me = context.read<AppStatesProvider>().me;
    final feedFilters = context.read<AppFeedProvider>().feedFilters;
    final selectedFollowingSets = me.followSets
        .where((item) => feedFilters.selectedFollowingSets.contains(item.id))
        .toList();
    final selectedFollowingHashtags = me.interestSets
        .where((item) => feedFilters.selectedFollowingHashtags.contains(item))
        .toList();
    setState(() {
      _followingSelected = feedFilters.followingSelected;
      _articlesSelected = feedFilters.articlesSelected;
      _liveActivitiesSelected = feedFilters.liveActivitiesSelected;
      _repliesSelected = feedFilters.repliesSelected;
      _repostsSelected = feedFilters.repostsSelected;
      _selectedFollowingSets = selectedFollowingSets;
      _selectedFollowingHashtags = selectedFollowingHashtags;
    });
  }

  void _showDropdownMenu(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        ThemeData themeData = Theme.of(context);
        MyThemeExtension themeExtension =
            themeData.extension<MyThemeExtension>()!;
        final me = context.watch<AppStatesProvider>().me;
        return AlertDialog(
          title: Text('Feed filters'),
          contentPadding: EdgeInsets.symmetric(horizontal: 24),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Row(
                        children: const [
                          Icon(Icons.group_sharp),
                          SizedBox(width: 8),
                          Text('Only following'),
                        ],
                      ),
                      value: _followingSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          _followingSelected = value ?? false;
                        });
                      },
                    ),
                    const Divider(),
                    if (me.followSets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Following sets',
                          style: TextStyle(color: themeExtension.textDimColor),
                        ),
                      ),
                      ...me.followSets.map((FollowSet item) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.all(0),
                          title: Row(
                            children: [
                              const Icon(Icons.list_sharp),
                              const SizedBox(width: 8),
                              Text(item.name),
                            ],
                          ),
                          value: _selectedFollowingSets.contains(item),
                          onChanged: (bool? value) {
                            setState(() {
                              if (_selectedFollowingSets.contains(item)) {
                                _selectedFollowingSets.remove(item);
                              } else {
                                _selectedFollowingSets.add(item);
                              }
                            });
                          },
                        );
                      }),
                      Center(
                        child: TextButton(
                          child: Text('Clear set selection'),
                          onPressed: () {
                            setState(() {
                              _selectedFollowingSets.clear();
                            });
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                    if (me.interestSets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Following hashtags',
                          style: TextStyle(color: themeExtension.textDimColor),
                        ),
                      ),
                      ...me.interestSets.map((item) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.all(0),
                          title: Row(
                            children: [
                              const Icon(Icons.tag_sharp),
                              const SizedBox(width: 8),
                              Text(item),
                            ],
                          ),
                          value: _selectedFollowingHashtags.contains(item),
                          onChanged: (bool? value) {
                            setState(() {
                              if (_selectedFollowingHashtags.contains(item)) {
                                _selectedFollowingHashtags.remove(item);
                              } else {
                                _selectedFollowingHashtags.add(item);
                              }
                            });
                          },
                        );
                      }),
                      Center(
                        child: TextButton(
                          child: Text('Clear hashtag selection'),
                          onPressed: () {
                            setState(() {
                              _selectedFollowingHashtags.clear();
                            });
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Additional contents',
                        style: TextStyle(color: themeExtension.textDimColor),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Row(
                        children: const [
                          Icon(Icons.menu_book),
                          SizedBox(width: 8),
                          Text('Articles'),
                        ],
                      ),
                      value: _articlesSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          _articlesSelected = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Row(
                        children: const [
                          Icon(Icons.play_arrow_rounded),
                          SizedBox(width: 8),
                          Text('Live activities'),
                        ],
                      ),
                      value: _liveActivitiesSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          _liveActivitiesSelected = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Row(
                        children: const [
                          Icon(Icons.reply),
                          SizedBox(width: 8),
                          Text('Replies'),
                        ],
                      ),
                      value: _repliesSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          _repliesSelected = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: Row(
                        children: const [
                          Icon(Icons.repeat),
                          SizedBox(width: 8),
                          Text('Reposts'),
                        ],
                      ),
                      value: _repostsSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          _repostsSelected = value ?? false;
                        });
                      },
                    ),
                    const Divider(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                final appFeedMenu = context.read<AppFeedProvider>();
                final feedFilters = FeedFilters(
                  followingSelected: _followingSelected,
                  articlesSelected: _articlesSelected,
                  liveActivitiesSelected: _liveActivitiesSelected,
                  repliesSelected: _repliesSelected,
                  repostsSelected: _repostsSelected,
                  selectedFollowingSets: _selectedFollowingSets
                      .map((toElement) => toElement.id)
                      .toList(),
                  selectedFollowingHashtags: _selectedFollowingHashtags,
                );
                appFeedMenu.setFeedFilters(feedFilters);
                widget.onChange!(feedFilters);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showDropdownMenu(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Feed filters'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
          ),
          Icon(Icons.filter_alt),
        ],
      ),
    );
  }
}
