import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_notification.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/message.dart';
import 'package:wherostr_social/services/nostr.dart';

class MessagesBadgeButton extends StatefulWidget {
  final Function()? onPressed;
  final bool initializedMessages;

  const MessagesBadgeButton({
    super.key,
    this.initializedMessages = false,
    this.onPressed,
  });
  @override
  State createState() => MessagesBadgeButtonState();
}

class MessagesBadgeButtonState extends State<MessagesBadgeButton> {
  int _badgeCount = 0;
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;
  bool _initializedMessages = false;

  @override
  void initState() {
    super.initState();
    _initializedMessages = widget.initializedMessages;
    subscribe();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessagesBadgeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initializedMessages != oldWidget.initializedMessages) {
      _initializedMessages = widget.initializedMessages;
      if (_initializedMessages) {
        subscribe();
      }
    }
  }

  void subscribe() async {
    final appNotification = context.read<AppNotificationProvider>();
    final appState = context.read<AppStatesProvider>();
    if (_initializedMessages != true) return;
    final List<NostrFilter> filters = [];
    final relays = await appState.me.fetchDMRelayList();
    final since = appNotification.messagingLastSeen;
    filters.add(NostrFilter(
      kinds: [1059],
      p: [appState.me.pubkey],
      since: DateTime.fromMillisecondsSinceEpoch(since)
          .subtract(Duration(days: 2)),
    ));
    filters.add(NostrFilter(
      kinds: [4],
      p: [appState.me.pubkey],
      since: DateTime.fromMillisecondsSinceEpoch(since)
          .add(Duration(milliseconds: 1000)),
    ));
    filters.add(NostrFilter(
      kinds: [4],
      authors: [appState.me.pubkey],
      since: DateTime.fromMillisecondsSinceEpoch(since)
          .add(Duration(milliseconds: 1000)),
    ));

    final keyPairs = await AppSecret.read();
    _newEventStream = NostrService.subscribe(
      filters,
      relays: relays,
    );
    _newEventListener = _newEventStream!.stream.listen((e) async {
      final newEvent = e;
      late DataMessage dataMessage;
      if (e.kind == 1059) {
        final event = await Nip17.decode(newEvent, keyPairs!.private);
        if ((event.createdAt?.millisecondsSinceEpoch.compareTo(since) ?? 0) <=
            0) {
          return;
        }
        dataMessage = DataMessage(
          createdAt: event.createdAt!.millisecondsSinceEpoch,
          eventId: event.id!,
          plainText: event.content!,
          sender: event.pubkey,
          receiver: event.getTagValue('p')!,
          replyId: event.getTagValue('e'),
        );
        if (appState.me.pubkey != event.pubkey) {
          setState(() {
            _badgeCount += 1;
          });
        }
      } else if (e.kind == 4) {
        final msg =
            await Nip4.decode(newEvent, keyPairs!.public, keyPairs.private);
        if ((msg?.createdAt?.millisecondsSinceEpoch.compareTo(since) ?? 0) <=
            0) {
          return;
        }
        dataMessage = DataMessage(
          createdAt: msg!.createdAt!.millisecondsSinceEpoch,
          eventId: newEvent.id!,
          plainText: msg.content!,
          sender: msg.sender,
          receiver: msg.receiver,
          replyId: msg.replyId,
        );
        if (appState.me.pubkey != msg.sender) {
          setState(() {
            _badgeCount += 1;
          });
        }
      }
      await MessageService.isar.writeTxn(() async {
        await MessageService.isar.dataMessages.put(dataMessage);
      });
    });
  }

  Future<void> unsubscribe() async {
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
    ThemeData themeData = Theme.of(context);
    return IconButton(
      color: themeData.colorScheme.primary,
      icon: _badgeCount > 0
          ? Badge.count(
              count: _badgeCount,
              child: Icon(Icons.message),
            )
          : Icon(Icons.message),
      onPressed: () {
        widget.onPressed?.call();
        final appNotifications = context.read<AppNotificationProvider>();
        appNotifications
            .setMessagingLastSeen(DateTime.now().millisecondsSinceEpoch);
        setState(() {
          _badgeCount = 0;
        });
      },
    );
  }
}
