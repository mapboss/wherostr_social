import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/formatter.dart';
import 'package:wherostr_social/widgets/post_menu.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

class PostComposer extends StatefulWidget {
  final NostrEvent event;
  final bool enableShowProfileAction;
  final bool enableMenu;
  final Widget? trailing;

  const PostComposer({
    super.key,
    required this.event,
    this.enableShowProfileAction = true,
    this.enableMenu = true,
    this.trailing,
  });

  @override
  State createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  NostrUser? _author;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    try {
      final user = await NostrService.fetchUser(widget.event.pubkey);
      if (mounted) {
        setState(() {
          _author = user;
        });
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return _author == null
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
            minTileHeight: 64.0,
            horizontalTitleGap: 8,
            leading: InkWell(
              onTap: widget.enableShowProfileAction == true
                  ? () => context.read<AppStatesProvider>().navigatorPush(
                        widget: Profile(
                          user: _author!,
                        ),
                      )
                  : null,
              child: ProfileAvatar(url: _author!.picture),
            ),
            title: ProfileDisplayName(
              user: _author!,
              textStyle: themeData.textTheme.titleMedium,
              withBadge: true,
            ),
            subtitle: _author!.nip05 == null
                ? null
                : Text(
                    _author!.nip05!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: widget.trailing ??
                Transform.translate(
                  offset: Offset(widget.enableMenu == true ? 4 : 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(widget.event.createdAt),
                        style: TextStyle(color: themeExtension.textDimColor),
                      ),
                      if (widget.enableMenu == true)
                        PostMenu(
                          event: widget.event,
                          user: _author,
                        )
                    ],
                  ),
                ),
          );
  }
}
