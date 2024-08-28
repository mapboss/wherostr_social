import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';

List<NostrUser> filterProfileList({
  String? keyword,
  List<NostrUser>? additionalData,
}) {
  final List<NostrUser> profileList = [
    ...NostrService.profileList.entries.map((item) => item.value),
    ...(additionalData ?? []),
  ];
  Set<String> seenSecondStrings = {};
  List<NostrUser> uniqueLists = [];
  for (NostrUser innerList in profileList) {
    if (!seenSecondStrings.contains(innerList.pubkey)) {
      seenSecondStrings.add(innerList.pubkey);
      uniqueLists.add(innerList);
    }
  }
  final List<NostrUser> sortedProfileList;
  if ((keyword ?? '') == '') {
    sortedProfileList = uniqueLists;
  } else {
    final fuse = Fuzzy<NostrUser>(
      uniqueLists,
      options: FuzzyOptions(
        findAllMatches: true,
        keys: [
          WeightedKey(
            name: 'displayName',
            getter: (item) => item.displayName,
            weight: 0.75,
          ),
          WeightedKey(
            name: 'nip05',
            getter: (item) => item.nip05 ?? '',
            weight: 0.25,
          ),
        ],
      ),
    );
    sortedProfileList =
        fuse.search(keyword!).map((result) => result.item).toList();
  }
  return sortedProfileList;
}

class ProfileList extends StatelessWidget {
  final String? keyword;
  final void Function(NostrUser profile)? onProfileSelected;

  const ProfileList({
    super.key,
    this.keyword,
    this.onProfileSelected,
  });

  void _handleProfileItemPressed(NostrUser profile) {
    onProfileSelected?.call(profile);
  }

  Future<List<NostrUser>?> _searchUser(String keyword) async {
    List<NostrUser>? resultsFromSearch;
    if (keyword != '') {
      try {
        resultsFromSearch = (await NostrService.search(keyword, kinds: [0]))
            .map((item) => NostrUser.fromEvent(item))
            .toList();
      } catch (error) {}
    }
    return resultsFromSearch;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return FutureBuilder(
      future: _searchUser(keyword ?? ''),
      builder:
          (BuildContext context, AsyncSnapshot<List<NostrUser>?> snapshot) {
        List<Widget> children = filterProfileList(
          keyword: keyword,
          additionalData: snapshot.data ?? [],
        )
            .map(
              (item) => ListTile(
                key: Key(item.pubkey),
                onTap: () => _handleProfileItemPressed(item),
                minTileHeight: 64,
                horizontalTitleGap: 8,
                leading: ProfileAvatar(url: item.picture),
                title: ProfileDisplayName(
                  user: item,
                  textStyle: themeData.textTheme.titleMedium,
                  withBadge: true,
                ),
                subtitle: item.nip05 == null
                    ? null
                    : Text(
                        item.nip05!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            )
            .take(50)
            .toList();
        return ListView(
          children: [
            if ((keyword ?? '') != '' &&
                snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            ...children,
          ],
        );
      },
    );
  }
}
