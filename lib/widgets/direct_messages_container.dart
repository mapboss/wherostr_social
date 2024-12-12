import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/message.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/message_item.dart';
import 'package:wherostr_social/widgets/post_item.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

class DirectMessagesContainer extends StatefulWidget {
  final String pubkey;

  const DirectMessagesContainer({
    super.key,
    required this.pubkey,
  });

  @override
  State<DirectMessagesContainer> createState() =>
      _DirectMessagesContainerState();
}

class _DirectMessagesContainerState extends State<DirectMessagesContainer> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  NostrUser? _user;
  DataEvent? _quotedEvent;
  bool _isEmpty = true;
  bool _isLoading = false;
  bool _nip17Enabled = false;
  final List<DataEvent> _messages = [];

  Stream<List<DataMessage>>? _newMessageStream;
  StreamSubscription<List<DataMessage>>? _newMessageListener;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_checkIfTextIsNotEmpty);
    initialize();
  }

  void initialize() async {
    NostrUser user = await NostrService.fetchUser(widget.pubkey);
    // _nip17Enabled =
    await Future.wait([
      initMessages(widget.pubkey),
      user.fetchDMRelayList(),
      user.fetchRelayList(),
    ]);
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_checkIfTextIsNotEmpty);
    _messageController.dispose();
    _focusNode.dispose();
    _newMessageListener?.cancel();
    super.dispose();
  }

  void _handleOnReplyTap(DataEvent event) {
    _focusNode.unfocus();
    setState(() {
      _quotedEvent = event;
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        _focusNode.requestFocus();
      });
    });
  }

  void _checkIfTextIsNotEmpty() {
    setState(() {
      _isEmpty = !_messageController.text.trim().isNotEmpty;
    });
  }

  void _handleSendPressed() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final appState = context.read<AppStatesProvider>();
      _focusNode.unfocus();
      final keyPairs = await AppSecret.read();
      String content = _messageController.text.trim();
      final receiverRelayList = await _user?.fetchDMRelayList();
      if ((receiverRelayList?.length ?? 0) > 0) {
        final innerEvent = await Nip17.encodeInnerEvent(
          widget.pubkey,
          content,
          _quotedEvent != null ? _quotedEvent!.id! : '',
          appState.me.pubkey,
          keyPairs!.private,
        );
        final msgReceiver = await Nip17.encode(
          innerEvent,
          widget.pubkey,
          appState.me.pubkey,
          keyPairs.private,
        );
        final msgSender = await Nip17.encode(
          innerEvent,
          appState.me.pubkey,
          appState.me.pubkey,
          keyPairs.private,
        );
        // final message = DataMessage(
        //   eventId: innerEvent.id!,
        //   plainText: content,
        //   receiver: widget.pubkey,
        //   sender: keyPairs.public,
        //   replyId: _quotedEvent?.id,
        //   createdAt: innerEvent.createdAt!.microsecondsSinceEpoch,
        // );
        // await MessageService.isar.dataMessages.put(message);
        final senderRelayList = await appState.me.fetchDMRelayList();
        await Future.wait([
          NostrService.instance.relaysService.sendEventToRelaysAsync(
            msgSender,
            timeout: Duration(seconds: 10),
            relays: senderRelayList.toListString(),
          ),
          NostrService.instance.relaysService.sendEventToRelaysAsync(
            msgReceiver,
            timeout: Duration(seconds: 10),
            relays: receiverRelayList?.toListString(),
          )
        ]);
      } else {
        final event = await Nip4.encode(keyPairs!.public, widget.pubkey,
            content, _quotedEvent?.id ?? '', keyPairs.private);
        await event.publish();
      }
      setState(() {
        _quotedEvent = null;
      });
      _messageController.clear();
    } catch (error) {
      AppUtils.handleError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> initMessages(String pubkey) async {
    _newMessageStream = MessageService.isar.dataMessages
        .filter()
        .senderEqualTo(pubkey)
        .or()
        .receiverEqualTo(pubkey)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
    _newMessageListener = _newMessageStream?.listen((items) {
      setState(() {
        _messages.insertAll(0, items.map((e) => e.toEvent()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _user != null
            ? InkWell(
                onTap: () => appState.navigatorPush(
                  widget: Profile(
                    user: _user!,
                  ),
                ),
                child: Row(
                  children: [
                    ProfileAvatar(
                      url: _user?.picture,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileDisplayName(
                            user: _user,
                            withBadge: true,
                          ),
                          if ((_user!.nip05 ?? '') != '') ...[
                            Text(
                              _user!.nip05!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: themeData.textTheme.bodyMedium!
                                  .copyWith(color: themeExtension.textDimColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      return ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          if (_messages.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('No items'),
                                ],
                              ),
                            );
                          }
                          final event = _messages[index];
                          return Column(
                            crossAxisAlignment:
                                event.pubkey == appState.me.pubkey
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              IntrinsicWidth(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                  child: MessageItem(
                                    event: event,
                                    isCompact: false,
                                    showAvatar: false,
                                    showName: false,
                                    showTime: true,
                                    enableActionBar: true,
                                    onReplyTap: () => _handleOnReplyTap(event),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: themeData.colorScheme.surfaceDim,
                            prefixIcon: const Icon(Icons.comment_outlined),
                            hintText: 'Send a message',
                          ),
                          readOnly: _isLoading,
                        ),
                      ),
                      SizedBox(width: 8),
                      _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(),
                                ),
                              ))
                          : IconButton(
                              onPressed: _isEmpty ? null : _handleSendPressed,
                              icon: Icon(Icons.send),
                              color: _isEmpty
                                  ? null
                                  : themeData.colorScheme.primary,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_quotedEvent != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: Material(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            foregroundDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeData.colorScheme.primary,
                              ),
                            ),
                            child: LimitedBox(
                              maxHeight: 108,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                primary: false,
                                child: PostItem(
                                  key: ValueKey(_quotedEvent!.id),
                                  event: _quotedEvent!,
                                  enableTap: false,
                                  enableElementTap: false,
                                  enableMenu: false,
                                  enableActionBar: false,
                                  enableLocation: false,
                                  enableProofOfWork: false,
                                  enableShowProfileAction: false,
                                  depth: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _quotedEvent = null;
                                }),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
