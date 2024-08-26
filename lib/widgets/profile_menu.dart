import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class ProfileMenu extends StatefulWidget {
  final NostrUser user;

  const ProfileMenu({super.key, required this.user});

  @override
  State createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  bool _isMe = false;
  bool _isFollowing = false;
  bool? _isMuted;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    _isMe = me.pubkey == widget.user.pubkey;
    _isFollowing = me.following.contains(widget.user.pubkey);
    _isMuted = me.muteList.contains(widget.user.pubkey);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_horiz),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: 'nostr:${widget.user.npub}',
              ),
            );
            AppUtils.showSnackBar(
              text: 'Nostr link copied',
              status: AppStatus.success,
            );
          },
          leadingIcon: const Icon(Icons.link),
          child: const Text('Copy user Nostr link'),
        ),
        MenuItemButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: widget.user.npub,
              ),
            );
            AppUtils.showSnackBar(
              text: 'Public key copied',
              status: AppStatus.success,
            );
          },
          leadingIcon: const Icon(Icons.person),
          child: const Text('Copy public key'),
        ),
        if (!_isMe) ...[
          if (_isFollowing == true) ...[
            MenuItemButton(
              onPressed: () async {
                final me = context.read<AppStatesProvider>().me;
                await me.unfollow(widget.user.pubkey);
                setState(() {
                  _isFollowing = false;
                });
              },
              leadingIcon: Icon(
                Icons.person_remove,
                color: themeData.colorScheme.error,
              ),
              child: Text(
                'Unfollow user',
                style: TextStyle(color: themeData.colorScheme.error),
              ),
            ),
          ] else ...[
            MenuItemButton(
              onPressed: () async {
                final me = context.read<AppStatesProvider>().me;
                await me.follow(widget.user.pubkey);
                setState(() {
                  _isFollowing = true;
                });
              },
              leadingIcon: const Icon(Icons.person_add),
              child: const Text('Follow user'),
            ),
          ],
          if (_isMuted == true) ...[
            MenuItemButton(
              onPressed: () async {
                final unmute = context.read<AppStatesProvider>().unmute;
                await unmute(widget.user.pubkey);
                setState(() {
                  _isMuted = false;
                });
              },
              leadingIcon: const Icon(Icons.person),
              child: const Text('Unmute user'),
            ),
          ] else ...[
            MenuItemButton(
              onPressed: () async {
                final mute = context.read<AppStatesProvider>().mute;
                await mute(widget.user.pubkey);
                setState(() {
                  _isMuted = true;
                });
              },
              leadingIcon: Icon(
                Icons.person_off,
                color: themeData.colorScheme.error,
              ),
              child: Text(
                'Mute user',
                style: TextStyle(color: themeData.colorScheme.error),
              ),
            ),
          ],
          MenuItemButton(
            onPressed: () async {
              final me = context.read<AppStatesProvider>().me;
              await me.reportUser(widget.user.pubkey);
              AppUtils.showSnackBar(
                text: 'User reported',
                status: AppStatus.success,
              );
            },
            leadingIcon: Icon(
              Icons.report,
              color: themeData.colorScheme.error,
            ),
            child: Text(
              'Report user',
              style: TextStyle(color: themeData.colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}
