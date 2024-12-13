import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_settings.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/services/message.dart';
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

  Stream<List<DataMessage>>? _newMessageStream;
  StreamSubscription<List<DataMessage>>? _newMessageListener;

  List<DataEvent> _topics = [];
  final groupedByPartner = <String, DataEvent>{};

  Future<void> initMessages() async {
    final appState = context.read<AppStatesProvider>();
    final sentMessages = await MessageService.isar.dataMessages
        .filter()
        .senderEqualTo(appState.me.pubkey)
        .and()
        .not()
        .receiverEqualTo(appState.me.pubkey)
        .findAll();

    final receivedMessages = await MessageService.isar.dataMessages
        .filter()
        .receiverEqualTo(appState.me.pubkey)
        .and()
        .not()
        .senderEqualTo(appState.me.pubkey)
        .findAll();

    for (var item in sentMessages) {
      final existingMessage = groupedByPartner[item.receiver];
      if (existingMessage == null ||
          item.createdAt.compareTo(
                  existingMessage.createdAt!.millisecondsSinceEpoch) >
              0) {
        groupedByPartner[item.receiver] = item.toEvent();
      }
    }
    for (var item in receivedMessages) {
      final existingMessage = groupedByPartner[item.sender];
      if (existingMessage == null ||
          item.createdAt.compareTo(
                  existingMessage.createdAt!.millisecondsSinceEpoch) >
              0) {
        groupedByPartner[item.sender] = item.toEvent();
      }
    }
    _topics = groupedByPartner.values.toList();
    setState(() {
      _topics.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    });
    subscribeMessages(_topics.firstOrNull?.createdAt);
  }

  void subscribeMessages(DateTime? since) {
    final appState = context.read<AppStatesProvider>();
    _newMessageStream = MessageService.isar.dataMessages
        .filter()
        .createdAtGreaterThan(since?.millisecondsSinceEpoch ?? 0)
        .watch(fireImmediately: true);
    _newMessageListener = _newMessageStream?.listen((items) {
      for (var item in items) {
        late DataEvent? existingMessage;
        late String key;
        if (item.receiver == appState.me.pubkey) {
          key = item.sender;
        } else if (item.sender == appState.me.pubkey) {
          key = item.receiver;
        }
        existingMessage = groupedByPartner[key];
        if (existingMessage == null ||
            item.createdAt.compareTo(
                    existingMessage.createdAt!.millisecondsSinceEpoch) >
                0) {
          groupedByPartner[key] = item.toEvent();
        }
      }
      _topics = groupedByPartner.values.toList();
      setState(() {
        _topics.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    final appSettings = context.read<AppSettingsProvider>();
    if (appSettings.initializedMessages) {
      initMessages();
      // subscribe();
    }
  }

  // @override
  // void dispose() {
  //   unsubscribe();
  //   super.dispose();
  // }

  Future<void> unsubscribe() async {
    if (_newEventListener != null) {
      await _newEventListener!.cancel();
      _newEventListener = null;
    }
    if (_newEventStream != null) {
      _newEventStream!.close();
      _newEventStream = null;
    }
    if (_newMessageListener != null) {
      await _newMessageListener?.cancel();
      _newMessageListener = null;
    }
    if (_newMessageStream != null) {
      _newMessageStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStatesProvider>();
    final appSettings = context.watch<AppSettingsProvider>();
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Builder(
        builder: (context) {
          // if (_topics.isEmpty && !appSettings.initializedMessages) {
          //   return const Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Text('Loading'),
          //       ],
          //     ),
          //   );
          // }
          if (_topics.isEmpty) {
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
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'How Nostr DMs Work',
                        style: themeData.textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Nostr direct messages use public and private keys to ensure secure communication. Messages are sent via relays, which help distribute and sync them across devices. Only the intended recipient can decrypt and read your messages, ensuring complete privacy.',
                          style: TextStyle(color: themeExtension.textDimColor),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          late Completer completer;
                          showDialog(
                            context: context,
                            useRootNavigator: true,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      completer.completeError('Cancel');
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
                          final keyPairs = await AppSecret.read();
                          await initMessages();
                          completer =
                              MessageService.sync(keyPairs!, appState.me);
                          await completer.future;
                          await appSettings.setInitializedMessages(true);
                          appState.navigatorPop();
                        },
                        child: const Text("Start Using DMs"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              final event = _topics[index];
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
