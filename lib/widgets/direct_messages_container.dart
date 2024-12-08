import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/message_item.dart';
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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_checkIfTextIsNotEmpty);
    initialize();
  }

  void initialize() async {
    NostrUser user = await NostrService.fetchUser(widget.pubkey);
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
      _focusNode.unfocus();
      final keyPairs = await AppSecret.read();
      String content = _messageController.text.trim();
      final event = await Nip17.encodeSealedGossipDM(
          widget.pubkey,
          content,
          _quotedEvent != null ? _quotedEvent!.id! : '',
          keyPairs!.public,
          keyPairs.private);
      final me = context.read<AppStatesProvider>().me;
      await event.publish(
        relays: me.relayList,
      );
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

  Future<List<DataEvent>> getDirectMessages(String pubkey) async {
    final rows = await DataMessage.database.query(
      DataMessage.tableName,
      orderBy: 'created_at DESC',
      where: "sender = '$pubkey' or reciever = '$pubkey'",
    );
    return rows.map((toElement) {
      return DataMessage.fromMap(toElement).toEvent();
    }).toList();
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: getDirectMessages(widget.pubkey),
              builder: (context, snapshot) {
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    if (snapshot.data == null) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No items'),
                          ],
                        ),
                      );
                    }
                    final event = snapshot.data![index];
                    return Column(
                      crossAxisAlignment: event.pubkey == appState.me.pubkey
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
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
                        color: _isEmpty ? null : themeData.colorScheme.primary,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
