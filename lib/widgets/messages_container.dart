import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wherostr_social/models/app_notification.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_settings.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/direct_messages_container.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_content.dart';

class MessagesContainer extends StatefulWidget {
  const MessagesContainer({super.key});
  @override
  State createState() => MessagesContainerState();
}

class MessagesContainerState extends State<MessagesContainer> {
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;
  final _debouncer = Debouncer();

  Future<List<DataEvent>> getAllMessages(BuildContext context) async {
    final appState = context.read<AppStatesProvider>();
    const query = '''
    WITH combined AS (
        SELECT *, receiver AS chat_partner
        FROM ${DataMessage.tableName}
        WHERE sender == ?
        UNION
        SELECT *, sender AS chat_partner
        FROM ${DataMessage.tableName}
        WHERE receiver == ?
    ),
    ranked_messages AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY chat_partner 
                ORDER BY created_at DESC
            ) AS rank
        FROM combined
    )
    SELECT 
        *
    FROM ranked_messages
    WHERE rank = 1
    ORDER BY created_at DESC;
    ''';
    final rows = await DataMessage.database
        .rawQuery(query, [appState.me.pubkey, appState.me.pubkey]);
    return rows.map((e) => DataMessage.fromMap(e).toEvent()).toList();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _subscribe();
  // }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final appNotification = context.read<AppNotificationProvider>();
    final appState = context.read<AppStatesProvider>();
    final List<NostrFilter> filters = [];
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
    final relays = await appState.me.fetchDMRelayList();
    final createdAt = rows.isEmpty ? null : rows[0]['created_at'] as int;
    if (appNotification.notificationDirectMessages) {
      filters.add(NostrFilter(
        kinds: [1059],
        p: [appState.me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .subtract(Duration(days: 2)),
      ));
      filters.add(NostrFilter(
        kinds: [4],
        p: [appState.me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .add(Duration(milliseconds: 1000)),
      ));
      filters.add(NostrFilter(
        kinds: [4],
        authors: [appState.me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .add(Duration(milliseconds: 1000)),
      ));
    }
    final keyPairs = await AppSecret.read();
    final batch = DataMessage.database.batch();
    _newEventStream = NostrService.subscribe(
      filters,
      relays: relays,
      onEose: (relay, ease) async {
        if (batch.length == 0) return;
        _debouncer.debounce(
          duration: Duration(milliseconds: 2000),
          onDebounce: () async {
            final appSettings = context.read<AppSettingsProvider>();
            await batch.commit();
            await appSettings.setInitializedMessages(true);
            appState.navigatorPop();
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
            receiver: newEvent.getTagValue('p')!,
            replyId: newEvent.getTagValue('e'),
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
            receiver: msg.receiver,
            replyId: msg.replyId,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
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
    final appState = context.read<AppStatesProvider>();
    final appSettings = context.watch<AppSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: FutureBuilder(
        future: getAllMessages(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Loading'),
                ],
              ),
            );
          }
          if ((!snapshot.hasData || (snapshot.data?.isEmpty ?? true))) {
            if (appSettings.initializedMessages) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No items'),
                  ],
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        useRootNavigator: true,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Starting...'),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            ),
                            content: const Text('Syncing all messages...'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _unsubscribe();
                                  appState.navigatorPop();
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                      final relays = await appState.me.fetchDMRelayList();
                      if (relays.isEmpty) {
                        await appState.me.initDMRelayList();
                      }
                      _subscribe();
                    },
                    child: Text("Start Using Direct Messages"),
                  )
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              final event = snapshot.data![index];
              if (event.pubkey == appState.me.pubkey &&
                  event.getTagValue('p') == appState.me.pubkey) {
                return SizedBox();
              }
              final chatPartner = event.pubkey == appState.me.pubkey
                  ? event.getTagValue('p')!
                  : event.pubkey;
              final composerEvent =
                  DataEvent(pubkey: chatPartner, createdAt: event.createdAt);
              return Material(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        final appState = context.read<AppStatesProvider>();
                        appState.navigatorPush(
                          isBottomNavigationBarVisible: false,
                          widget: DirectMessagesContainer(pubkey: chatPartner),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostComposer(
                                event: composerEvent, enableMenu: false),
                            PostContent(
                              content: event.content!.trim(),
                              enableMedia: false,
                              enablePreview: false,
                              enableElementTap: false,
                              depth: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
