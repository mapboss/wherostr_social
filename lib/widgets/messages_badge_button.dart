import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wherostr_social/models/app_notification.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/nostr.dart';

class MessagesBadgeButton extends StatefulWidget {
  final Function()? onPressed;

  const MessagesBadgeButton({
    super.key,
    this.onPressed,
  });
  @override
  State createState() => MessagesBadgeButtonState();
}

class MessagesBadgeButtonState extends State<MessagesBadgeButton> {
  int _badgeCount = 0;
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;

  final _debouncer = Debouncer();

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

  void _subscribe() async {
    final appNotification = context.read<AppNotificationProvider>();
    final appState = context.read<AppStatesProvider>();
    final relays = appState.me.relayList.clone();

    final List<int> kinds = [];
    if (appNotification.notificationDirectMessages) {
      kinds.add(1059);
      kinds.add(4);
    }

    var rows = [];
    try {
      rows = await DataMessage.database.query(
        DataMessage.tableName,
        orderBy: 'created_at DESC',
        limit: 1,
      );
      print('rows: $rows');
    } catch (err) {
      print('query: $err');
    }
    final filter = NostrFilter(
      kinds: kinds,
      p: [appState.me.pubkey],
      since: rows.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(rows[0]['created_at'] as int)
              .add(Duration(milliseconds: 1000)),
    );

    final keyPairs = await AppSecret.read();
    final batch = DataMessage.database.batch();
    _newEventStream = NostrService.subscribe(
      [filter],
      relays: relays,
      onEose: (relay, ease) async {
        if (batch.length == 0) return;
        _debouncer.debounce(
          duration: Duration(milliseconds: 1000),
          onDebounce: () async {
            print('COMMIT ${await batch.commit()}');
          },
        );
      },
    );
    _newEventListener = _newEventStream!.stream.listen((e) async {
      var newEvent = DataEvent.fromEvent(e);
      if (e.kind == 1059) {
        newEvent = await Nip17.decode(newEvent, keyPairs!.private);
        batch.insert(
          DataMessage.tableName,
          DataMessage(
            createdAt: newEvent.createdAt!.millisecondsSinceEpoch,
            id: newEvent.id!,
            plainText: newEvent.content!,
            sender: newEvent.pubkey,
            reciever: newEvent.getTagValue('p')!,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (e.kind == 4) {
        final msg =
            await Nip4.decode(newEvent, keyPairs!.public, keyPairs.private);
        batch.insert(
          DataMessage.tableName,
          DataMessage(
            createdAt: msg!.createdAt!.millisecondsSinceEpoch,
            id: newEvent.id!,
            plainText: msg.content!,
            sender: msg.sender,
            reciever: msg.receiver,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

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
