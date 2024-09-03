import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_content.dart';
import 'package:wherostr_social/widgets/post_item.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/profile_editing_container.dart';
import 'package:wherostr_social/widgets/profile_following.dart';
import 'package:wherostr_social/widgets/profile_menu.dart';
import 'package:wherostr_social/widgets/zap_form.dart';

class Profile extends StatefulWidget {
  final NostrUser user;
  final String heroTag;

  const Profile({
    super.key,
    required this.user,
    this.heroTag = 'profile-avatar',
  });

  @override
  State createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _isMe = false;
  bool _isFollowing = false;
  List<String>? _following;
  List<String>? _followers;
  bool _fetchingFollower = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    await widget.user.fetchProfile();
    setState(() {
      _isMe = me.pubkey == widget.user.pubkey;
      _isFollowing = me.following.contains(widget.user.pubkey);
    });
    widget.user.fetchFollowing().then((value) {
      if (mounted) {
        setState(() {
          _following = value;
        });
      }
    });
    if (widget.user.isFollowerFetched) {
      widget.user.fetchFollower().then((value) {
        if (mounted) {
          setState(() {
            _followers = value;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    final homeScaffoldKey = AppStatesProvider.homeScaffoldKey;
    final topPadding =
        MediaQuery.of(homeScaffoldKey.currentContext!).viewPadding.top;
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        const expandedHeight = kToolbarHeight + 120 + kToolbarHeight + 24;
        return [
          SliverAppBar(
            expandedHeight: expandedHeight,
            automaticallyImplyLeading: false,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              expandedTitleScale: 1,
              title: SizedBox(
                height: expandedHeight,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: CircleAvatar(
                          backgroundColor:
                              themeData.colorScheme.surface.withOpacity(0.54),
                          child: BackButton(
                            onPressed: () => appState.navigatorPop(
                                tryRootNavigatorFirst: false),
                            color: themeData.colorScheme.inverseSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: InkWell(
                            onTap: widget.user.picture == null
                                ? () {}
                                : () => showImageViewer(
                                      context,
                                      AppUtils.getImageProvider(
                                          widget.user.picture!),
                                      useSafeArea: true,
                                      swipeDismissible: true,
                                      doubleTapZoomable: true,
                                    ),
                            child: Hero(
                              tag: widget.heroTag,
                              child: ProfileAvatar(
                                url: widget.user.picture,
                                borderSize: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              titlePadding: EdgeInsets.only(
                  top: topPadding + ((kToolbarHeight - 40) / 2)),
              background: widget.user.banner == null
                  ? const DecoratedBox(decoration: wherostrBackgroundDecoration)
                  : InkWell(
                      onTap: () => showImageViewer(
                        context,
                        AppUtils.getImageProvider(widget.user.banner!),
                        useSafeArea: true,
                        swipeDismissible: true,
                        doubleTapZoomable: true,
                      ),
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        image: AppUtils.getImageProvider(widget.user.banner!),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeInCurve: Curves.easeInOutCubic,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Material(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      innerBoxIsScrolled ? 4 : 16, 4, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (innerBoxIsScrolled)
                        BackButton(
                          onPressed: () => appState.navigatorPop(
                              tryRootNavigatorFirst: false),
                        ),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileDisplayName(
                              user: widget.user,
                              textStyle: themeData.textTheme.titleLarge,
                              withBadge: true,
                            ),
                            if ((widget.user.nip05 ?? '') != '') ...[
                              Text(
                                widget.user.nip05!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: themeData.textTheme.bodyMedium!.copyWith(
                                    color: themeExtension.textDimColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(4, 0),
                        child: Row(
                          children: [
                            if (_isMe) ...[
                              OutlinedButton(
                                onPressed: () => appState.navigatorPush(
                                  widget: const ProfileEditingContainer(),
                                  rootNavigator: true,
                                ),
                                child: const Text('Edit profile'),
                              ),
                            ] else if (_isFollowing) ...[
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
                                      await appState.me
                                          .unfollow(widget.user.pubkey);
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
                                      style: TextStyle(
                                          color: themeData.colorScheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              FilledButton(
                                onPressed: () async {
                                  await appState.me.follow(widget.user.pubkey);
                                  setState(() {
                                    _isFollowing = true;
                                  });
                                },
                                child: const Text('Follow'),
                              ),
                            ],
                            ProfileMenu(
                              user: widget.user,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Material(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => appState.navigatorPush(
                                widget: ProfileFollowing(
                                  user: widget.user,
                                  initialIndex: 0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_following != null) ...[
                                    Text(
                                      NumberFormat.compact()
                                          .format(_following!.length),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    'Following',
                                    style: TextStyle(
                                      color: themeExtension.textDimColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                if (_followers == null) {
                                  setState(() {
                                    _fetchingFollower = true;
                                  });
                                  widget.user.fetchFollower().then((value) {
                                    if (mounted) {
                                      setState(() {
                                        _fetchingFollower = false;
                                        _followers = value;
                                      });
                                    }
                                  });
                                } else {
                                  appState.navigatorPush(
                                    widget: ProfileFollowing(
                                      user: widget.user,
                                      initialIndex: 1,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  _fetchingFollower
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 2),
                                          child: SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : Text(
                                          _followers == null
                                              ? '??'
                                              : NumberFormat.compact()
                                                  .format(_followers!.length),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Followers',
                                    style: TextStyle(
                                      color: themeExtension.textDimColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (widget.user.lud06 != null ||
                                widget.user.lud16 != null)
                              IconButton.outlined(
                                onPressed: () => appState.navigatorPush(
                                  widget: ZapForm(
                                    user: widget.user,
                                  ),
                                  rootNavigator: true,
                                ),
                                icon: const Icon(
                                  Icons.electric_bolt,
                                  color: Colors.orange,
                                ),
                              ),
                            IconButton.outlined(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  enableDrag: true,
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (context) {
                                    final TextEditingController
                                        npubTextController =
                                        TextEditingController();
                                    npubTextController.text = widget.user.npub;
                                    return DecoratedBox(
                                      decoration: wherostrBackgroundDecoration,
                                      child: SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ProfileDisplayName(
                                                user: widget.user,
                                                withBadge: true,
                                                textStyle: themeData
                                                    .textTheme.headlineMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                readOnly: true,
                                                controller: npubTextController,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  suffix: IconButton(
                                                    icon:
                                                        const Icon(Icons.copy),
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text:
                                                              npubTextController
                                                                  .text,
                                                        ),
                                                      );
                                                      AppUtils.showSnackBar(
                                                        text:
                                                            'User public key copied',
                                                        status:
                                                            AppStatus.success,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              QrImageView(
                                                backgroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                data: widget.user.npub,
                                                embeddedImage: const AssetImage(
                                                    'assets/app/logo-light.png'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.qr_code),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if ((widget.user.about ?? '') != '') ...[
                          PostContent(
                            content: widget.user.about!,
                            enablePreview: false,
                            enableMedia: false,
                            depth: 1,
                            wantKeepAlive: false,
                          ),
                          const SizedBox(height: 4),
                        ],
                        if ((widget.user.website ?? '') != '') ...[
                          Row(
                            children: [
                              const Icon(Icons.link),
                              const SizedBox(width: 4),
                              Flexible(
                                child: InkWell(
                                  child: Text(
                                    widget.user.website!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: themeData.colorScheme.primary,
                                    ),
                                  ),
                                  onTap: () => launchUrl(
                                    Uri.parse(widget.user.website!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (widget.user.lud06 != null ||
                            widget.user.lud16 != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.electric_bolt,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: InkWell(
                                  child: Text(
                                    (widget.user.lud16 ??
                                        widget.user.lud06?.substring(0, 32) ??
                                        ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: themeData.colorScheme.primary,
                                    ),
                                  ),
                                  onTap: () => appState.navigatorPush(
                                    widget: ZapForm(
                                      user: widget.user,
                                    ),
                                    rootNavigator: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: themeData.colorScheme.surfaceDim,
                  child: const SizedBox(width: double.infinity, height: 4),
                ),
              ],
            ),
          ),
        ];
      },
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Builder(
          builder: (context) {
            final scrollController = PrimaryScrollController.of(context);
            return NostrFeed(
              relays: appState.me.relayList.clone(),
              scrollController: scrollController,
              kinds: const [1, 6],
              authors: [
                widget.user.pubkey,
              ],
              includeMuted: true,
              itemBuilder: (context, item) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: PostItem(event: item),
              ),
            );
          },
        ),
      ),
    );
  }
}
