import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class PostMenu extends StatefulWidget {
  final DataEvent? event;
  final NostrUser? user;

  const PostMenu({super.key, this.event, this.user});

  @override
  State createState() => _PostMenuState();
}

class _PostMenuState extends State<PostMenu> {
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
    setState(() {
      _isMe = me.pubkey == widget.user?.pubkey;
      _isFollowing = me.following.contains(widget.user?.pubkey);
      _isMuted = me.muteList.contains(widget.user?.pubkey);
    });
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
        if (widget.event != null) ...[
          MenuItemButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      'nostr:${NostrService.instance.utilsService.encodeNevent(
                    eventId: widget.event!.id!,
                    pubkey: widget.event!.pubkey,
                  )}',
                ),
              );
              AppUtils.showSnackBar(
                text: 'Nostr link copied',
                status: AppStatus.success,
              );
            },
            leadingIcon: const Icon(Icons.link),
            child: const Text('Copy post Nostr link'),
          ),
          Divider(
            color: themeData.colorScheme.primary,
          ),
        ],
        if (widget.user != null) ...[
          MenuItemButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: 'nostr:${widget.user!.npub}',
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
                  text: widget.user!.npub,
                ),
              );
              AppUtils.showSnackBar(
                text: 'User public key copied',
                status: AppStatus.success,
              );
            },
            leadingIcon: const Icon(Icons.person),
            child: const Text('Copy user public key'),
          ),
        ],
        if (!_isMe && widget.user != null) ...[
          if (_isFollowing == true) ...[
            MenuItemButton(
              onPressed: () async {
                final me = context.read<AppStatesProvider>().me;
                await me.unfollow(widget.user!.pubkey);
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
                await me.follow(widget.user!.pubkey);
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
                await unmute(widget.user!.pubkey);
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
                await mute(widget.user!.pubkey);
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
              await me.reportUser(widget.user!.pubkey);
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
