import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/hashtag_search.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/profile_list.dart';
import 'package:wherostr_social/widgets/qr_scanner.dart';

const suggestedHashtags = [
  'nostr',
  'siamstr',
  'wherostr',
  'bitcoin',
  'btc',
  'art',
  'photography',
  'music',
  'food',
];
RegExp npubRegex =
    RegExp(r'(nostr:)npub1([acdefghjklmnpqrstuvwxyz023456789]+)');

class SearchContainer extends StatefulWidget {
  const SearchContainer({super.key});

  @override
  State<SearchContainer> createState() => _SearchContainerState();
}

class _SearchContainerState extends State<SearchContainer> {
  Future<bool> _handleScanned(BarcodeCapture data) async {
    final appState = context.read<AppStatesProvider>();
    final npub = data.barcodes.firstOrNull?.displayValue;
    if (npub != null) {
      try {
        AppUtils.showLoading();
        final pubkey = NostrService.instance.utilsService.decodeBech32(npub)[0];
        NostrUser user = await NostrService.fetchUser(pubkey);
        AppUtils.hideLoading();
        appState.navigatorPush(
          widget: Profile(
            user: user,
          ),
        );
        return true;
      } catch (error) {
        AppUtils.hideLoading();
        return false;
      }
    }
    return false;
  }

  Future<List<NostrUser>?> _searchUser(String keyword) async {
    List<NostrUser>? resultsFromSearch;
    if (keyword != '') {
      try {
        resultsFromSearch = (await NostrService.search(keyword, kinds: [0]))
            .map((item) => NostrUser.fromDataEvent(item))
            .toList();
      } catch (error) {}
    }
    return resultsFromSearch;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final focusNode = FocusNode();
    final homeScaffoldKey = AppStatesProvider.homeScaffoldKey;
    final topPadding =
        MediaQuery.of(homeScaffoldKey.currentContext!).viewPadding.top;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(topPadding),
        child: SizedBox(height: topPadding),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.openView,
                  child: IgnorePointer(
                    child: SearchBar(
                      elevation: const WidgetStatePropertyAll<double>(0),
                      controller: controller,
                      autoFocus: true,
                      focusNode: focusNode,
                      hintText: 'Search people, hashtags, or npub',
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onTap: () {
                        controller.openView();
                      },
                      onChanged: (_) {
                        controller.openView();
                      },
                      onTapOutside: (_) {
                        if (controller.isOpen) {
                          controller.closeView(null);
                        }
                        focusNode.unfocus();
                      },
                      leading: const Icon(Icons.search),
                    ),
                  ),
                );
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) async {
                final keyword = controller.text;
                String? pubkey;
                try {
                  final npub = keyword.startsWith('nostr:')
                      ? keyword.substring(6)
                      : keyword;
                  pubkey =
                      NostrService.instance.utilsService.decodeBech32(npub)[0];
                } catch (error) {}
                String? hashtag = pubkey != null
                    ? null
                    : keyword.startsWith('#')
                        ? keyword.substring(1)
                        : keyword;
                return ListTile.divideTiles(
                  context: context,
                  tiles: [
                    if (pubkey != null)
                      ProfileListTile(
                        pubkey: pubkey,
                        onTap: (NostrUser user) {
                          if (controller.isOpen) {
                            controller.closeView(null);
                          }
                          focusNode.unfocus();
                          context.read<AppStatesProvider>().navigatorPush(
                                widget: Profile(
                                  user: user,
                                ),
                              );
                        },
                      )
                    else if ((hashtag ?? '') != '')
                      ListTile(
                        minTileHeight: 64,
                        onTap: () {
                          if (controller.isOpen) {
                            controller.closeView(null);
                          }
                          focusNode.unfocus();
                          context.read<AppStatesProvider>().navigatorPush(
                                widget: HashtagSearch(
                                  hashtag: hashtag,
                                ),
                              );
                        },
                        leading: SizedBox(
                          width: 36,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.tag,
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          hashtag!,
                          style: themeData.textTheme.titleMedium,
                        ),
                      ),
                    FutureBuilder(
                      future: _searchUser(pubkey == null ? keyword : ''),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<NostrUser>?> snapshot) {
                        List<Widget> children = filterProfileList(
                          keyword: keyword,
                          additionalData: snapshot.data ?? [],
                        )
                            .map(
                              (item) => ListTile(
                                key: Key(item.pubkey),
                                onTap: () {
                                  if (controller.isOpen) {
                                    controller.closeView(null);
                                  }
                                  focusNode.unfocus();
                                  context
                                      .read<AppStatesProvider>()
                                      .navigatorPush(
                                        widget: Profile(
                                          user: item,
                                        ),
                                      );
                                },
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
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (pubkey == null &&
                                keyword != '' &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting)
                              const LinearProgressIndicator(),
                            ...children,
                          ],
                        );
                      },
                    ),
                  ],
                ).toList();
              },
            ),
          ),
          Material(
            child: ListTile(
              minTileHeight: 64,
              onTap: () {
                focusNode.unfocus();
                showModalBottomSheet(
                  isScrollControlled: true,
                  useRootNavigator: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.75,
                      child: QrScanner(
                        onScan: _handleScanned,
                      ),
                    );
                  },
                );
              },
              leading: SizedBox(
                width: 36,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: themeData.colorScheme.secondary,
                  ),
                ),
              ),
              title: Text(
                'Scan the Nostr public key (npub) QR code to add a friend.',
                style: themeData.textTheme.titleMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Material(
              child: ListView.separated(
                itemCount: suggestedHashtags.length,
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                },
                itemBuilder: (context, index) => ListTile(
                  minTileHeight: 64,
                  onTap: () {
                    focusNode.unfocus();
                    context.read<AppStatesProvider>().navigatorPush(
                          widget: HashtagSearch(
                            hashtag: suggestedHashtags[index],
                          ),
                        );
                  },
                  leading: SizedBox(
                    width: 36,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.tag,
                        color: themeData.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    suggestedHashtags[index],
                    style: themeData.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileListTile extends StatefulWidget {
  final String? pubkey;
  final void Function(NostrUser user)? onTap;

  const ProfileListTile({
    super.key,
    this.pubkey,
    this.onTap,
  });

  @override
  State<ProfileListTile> createState() => _ProfileListTileState();
}

class _ProfileListTileState extends State<ProfileListTile> {
  NostrUser? _user;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    try {
      NostrUser user = await NostrService.fetchUser(widget.pubkey!);
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (error) {}
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
            onTap: widget.onTap == null ? null : () => widget.onTap!(_user!),
          );
  }
}
