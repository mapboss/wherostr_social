import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_notification.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/services/nostr.dart';

class NotificationBadgeListTile extends StatefulWidget {
  final Function()? onTap;
  final bool selected;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;

  const NotificationBadgeListTile({
    super.key,
    required this.title,
    this.onTap,
    this.selected = false,
    this.leading,
    this.subtitle,
  });
  @override
  State createState() => NotificationBadgeListTileState();
}

class NotificationBadgeListTileState extends State<NotificationBadgeListTile> {
  int _badgeCount = 0;
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final appNotification = context.read<AppNotificationProvider>();
    final appState = context.read<AppStatesProvider>();
    final relays = appState.me.relayList.clone();

    final List<int> kinds = [];
    if (appNotification.notificationMentions) {
      kinds.add(1);
    }
    if (appNotification.notificationZaps) {
      kinds.add(9735);
    }
    if (appNotification.notificationReposts) {
      kinds.add(6);
      kinds.add(16);
    }
    if (appNotification.notificationReactions) {
      kinds.add(7);
    }
    final filter = NostrFilter(
      kinds: kinds,
      p: [appState.me.pubkey],
      since: DateTime.fromMillisecondsSinceEpoch(
        appNotification.notificationLastSeen,
      ),
      limit: 100,
    );
    _newEventStream = NostrService.subscribe(
      [filter],
      relays: relays,
      onEose: (relay, ease) async {},
    );
    _newEventListener = _newEventStream!.stream.listen((event) {
      if (event.pubkey == appState.me.pubkey) return;
      setState(() {
        _badgeCount += 1;
      });
    });
  }

  Future<void> _unsubscribe() async {
    if (_newEventListener != null) {
      await _newEventListener!.cancel();
      _newEventListener = null;
    }
    if (_newEventStream != null) {
      _newEventStream!.close();
      _newEventStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: widget.selected,
      title: widget.title,
      leading: widget.leading,
      trailing: _badgeCount > 0
          ? Badge.count(
              count: _badgeCount,
            )
          : null,
      onTap: () {
        widget.onTap?.call();
        final appNotifications = context.read<AppNotificationProvider>();
        appNotifications
            .setNotificationLastSeen(DateTime.now().millisecondsSinceEpoch);
        setState(() {
          _badgeCount = 0;
        });
      },
    );
  }
}
