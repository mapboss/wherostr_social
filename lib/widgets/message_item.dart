import 'dart:async';
import 'dart:convert';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:dart_nostr/nostr/model/nostr_events_stream.dart';
import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
// import 'package:wherostr_social/widgets/emoji_picker.dart';
import 'package:wherostr_social/widgets/post_content.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';
import 'package:wherostr_social/widgets/speech_bubble.dart';
// import 'package:wherostr_social/widgets/zap_form.dart';

const actionableKinds = [1311];

class MessageItem extends StatefulWidget {
  final DataEvent event;
  final bool enableActionBar;
  final bool isCompact;

  const MessageItem({
    super.key,
    required this.event,
    this.enableActionBar = true,
    this.isCompact = false,
  });

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;
  bool _isActionable = false;
  NostrUser? _user;
  int _reactionCount = 0;
  double _zapCount = 0;
  bool _isReacted = false;
  bool _isZapped = false;
  String? _emojiUrl;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  void initialize() {
    _isActionable = widget.enableActionBar
        ? actionableKinds.contains(widget.event.kind)
        : false;
    String userPubkey;
    switch (widget.event.kind) {
      case 9735:
        userPubkey = getZappee(event: widget.event) ?? widget.event.pubkey;
        break;
      default:
        userPubkey = widget.event.pubkey;
        break;
    }
    NostrService.fetchUser(userPubkey).then((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
    if (_isActionable) {
      NostrFilter filter = NostrFilter(
        kinds: const [7, 9735],
        e: [widget.event.id!],
      );
      NostrService.fetchEvents([filter]).then((events) {
        if (mounted) {
          widget.event.relatedEvents.addAll(events);
          updateCounts(events);
          subscribe();
        }
      });
    }
  }

  void subscribe() {
    _newEventStream = NostrService.subscribe([
      NostrFilter(
        since: DateTime.timestamp(),
        kinds: const [7, 9735],
        e: [widget.event.id!],
      ),
    ]);
    _newEventListener = _newEventStream!.stream.listen((event) {
      final e = DataEvent.fromEvent(event);
      widget.event.relatedEvents.add(e);
      updateCounts([e]);
    });
  }

  void unsubscribe() {
    if (_newEventListener != null) {
      _newEventListener!.cancel();
      _newEventListener = null;
    }
    if (_newEventStream != null) {
      _newEventStream!.close();
      _newEventStream = null;
    }
  }

  void updateCounts(List<NostrEvent> events) {
    if (mounted) {
      final me = context.read<AppStatesProvider>().me;
      bool isReacted = false;
      bool isZapped = false;
      String? emojiUrl;
      int reactionCount = _reactionCount;
      double zapCount = _zapCount;

      for (var event in events) {
        switch (event.kind) {
          case 7:
            if (!isReacted && event.pubkey == me.pubkey) {
              isReacted = true;
              emojiUrl = getEmojiUrl(
                event: event,
                emoji: event.content!,
              );
            }
            reactionCount += 1;
            continue;
          case 9735:
            if (event.tags != null) {
              List<String>? bolt11Tag =
                  event.tags!.where((tag) => tag[0] == 'bolt11').firstOrNull;
              List<String>? desc =
                  event.tags?.singleWhere((tag) => tag[0] == 'description');

              if (desc?.elementAtOrNull(1) != null) {
                if (me.pubkey == jsonDecode(desc!.elementAt(1))?['pubkey']) {
                  isZapped = true;
                }
              }
              if (bolt11Tag != null) {
                double amount =
                    Bolt11PaymentRequest(bolt11Tag[1]).amount.toDouble() *
                        100000000;
                zapCount += amount;
              }
            }
            continue;
        }
      }
      setState(() {
        _isReacted = isReacted;
        _isZapped = isZapped;
        _emojiUrl = emojiUrl;
        _reactionCount = reactionCount;
        _zapCount = zapCount;
      });
    }
  }

  void _handleReactPressed([List<String>? emojiTag]) {
    final customEmoji = emojiTag?.elementAtOrNull(1);
    setState(() {
      _isReacted = true;
      _emojiUrl = emojiTag?.elementAtOrNull(2);
    });
    final event = DataEvent(
      kind: 7,
      content: customEmoji == null ? '+' : ':$customEmoji:',
    );
    event.addTagIfNew(['e', widget.event.id!]);
    event.addTagIfNew(['p', widget.event.pubkey]);
    if (emojiTag != null) {
      event.addTagIfNew(emojiTag);
    }
    event.publish(autoGenerateTags: false);
  }

  Widget _contentWidget() {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final contentLeading = widget.isCompact && _user != null
        ? Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ProfileDisplayName(
              user: _user,
              withBadge: true,
              textStyle: TextStyle(color: themeExtension.textDimColor),
            ),
          )
        : null;
    switch (widget.event.kind) {
      case 9735:
        double? zapAmount = getZapAmount(event: widget.event);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contentLeading != null)
              PostContent(
                content: widget.event.content ?? '',
                depth: 1,
                contentLeading: contentLeading,
              ),
            Chip(
              backgroundColor: themeData.colorScheme.primary,
              padding: const EdgeInsets.all(4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              avatar: InkWell(
                onTap: () => context.read<AppStatesProvider>().navigatorPush(
                      widget: Profile(
                        user: _user!,
                      ),
                    ),
                child: ProfileAvatar(
                  url: _user?.picture,
                  borderSize: 1,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              label: Text.rich(
                style: const TextStyle(color: Colors.white),
                TextSpan(
                  children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.electric_bolt,
                        color: Colors.orange,
                      ),
                    ),
                    TextSpan(
                      text: ' ${NumberFormat.compact().format(zapAmount)} ',
                      style: themeData.textTheme.titleMedium!
                          .apply(color: Colors.white),
                    ),
                    const TextSpan(
                      text: 'sats',
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.isCompact && (widget.event.content ?? '') != '')
              PostContent(
                content: widget.event.content!,
                depth: 1,
                contentLeading: contentLeading,
              ),
          ],
        );
      default:
        return PostContent(
          content: widget.event.content ?? '',
          enablePreview: false,
          contentLeading: contentLeading,
        );
    }
  }

  Widget? _activityWidget() {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return (_isActionable && _reactionCount > 0 || _zapCount > 0)
        ? Row(
            children: [
              if (_reactionCount > 0) ...[
                _emojiUrl == null
                    ? Icon(
                        _isReacted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: _isReacted
                            ? themeData.colorScheme.secondary
                            : themeExtension.textDimColor,
                        size: 16,
                      )
                    : SizedBox(
                        width: 16,
                        height: 16,
                        child: Image(
                          width: 16,
                          height: 16,
                          image: AppUtils.getImageProvider(_emojiUrl!),
                        ),
                      ),
                const SizedBox(width: 4),
                Text(
                  NumberFormat.compact().format(_reactionCount),
                  maxLines: 1,
                  style: themeData.textTheme.labelMedium
                      ?.copyWith(color: themeExtension.textDimColor),
                ),
              ],
              if (_zapCount > 0) ...[
                if (_reactionCount > 0) const SizedBox(width: 16),
                Icon(
                  Icons.electric_bolt,
                  color:
                      _isZapped ? Colors.orange : themeExtension.textDimColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  NumberFormat.compact().format(_zapCount),
                  maxLines: 1,
                  style: themeData.textTheme.labelMedium
                      ?.copyWith(color: themeExtension.textDimColor),
                ),
              ],
            ],
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    // final appState = context.watch<AppStatesProvider>();
    final contentWidget = _contentWidget();
    final activityWidget = _activityWidget();
    if (widget.isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: InkWell(
              onTap: () => context.read<AppStatesProvider>().navigatorPush(
                    widget: Profile(
                      user: _user!,
                    ),
                  ),
              child: ProfileAvatar(
                url: _user?.picture,
                borderSize: 1,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contentWidget,
                  if (activityWidget != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: activityWidget,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: InkWell(
              onTap: () => context.read<AppStatesProvider>().navigatorPush(
                    widget: Profile(
                      user: _user!,
                    ),
                  ),
              child: ProfileAvatar(
                url: _user?.picture,
                borderSize: 1,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_user != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ProfileDisplayName(
                      user: _user,
                      withBadge: true,
                      textStyle: themeData.textTheme.bodySmall!
                          .apply(color: themeExtension.textDimColor),
                    ),
                  ),
                const SizedBox(height: 4),
                SpeechBubble(
                  padding: widget.event.kind == 9735
                      ? const EdgeInsets.symmetric(horizontal: 16)
                      : null,
                  color: widget.event.kind == 9735 ? Colors.orange : null,
                  child: contentWidget,
                ),
                if (activityWidget != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: activityWidget,
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 24),
                  //   child: Row(
                  //     children: [
                  //       if (_reactionCount > 0) ...[
                  //         _emojiUrl == null
                  //             ? Icon(
                  //                 _isReacted
                  //                     ? Icons.thumb_up
                  //                     : Icons.thumb_up_outlined,
                  //                 color: _isReacted
                  //                     ? themeData.colorScheme.secondary
                  //                     : themeExtension.textDimColor,
                  //                 size: 16,
                  //               )
                  //             : SizedBox(
                  //                 width: 16,
                  //                 height: 16,
                  //                 child: Image(
                  //                   width: 16,
                  //                   height: 16,
                  //                   image:
                  //                       AppUtils.getImageProvider(_emojiUrl!),
                  //                 ),
                  //               ),
                  //         const SizedBox(width: 4),
                  //         Text(
                  //           NumberFormat.compact().format(_reactionCount),
                  //           maxLines: 1,
                  //           style: themeData.textTheme.labelMedium
                  //               ?.copyWith(color: themeExtension.textDimColor),
                  //         ),
                  //       ],
                  //       if (_zapCount > 0) ...[
                  //         if (_reactionCount > 0) const SizedBox(width: 16),
                  //         Icon(
                  //           Icons.electric_bolt,
                  //           color: _isZapped
                  //               ? Colors.orange
                  //               : themeExtension.textDimColor,
                  //           size: 16,
                  //         ),
                  //         const SizedBox(width: 4),
                  //         Text(
                  //           NumberFormat.compact().format(_zapCount),
                  //           maxLines: 1,
                  //           style: themeData.textTheme.labelMedium
                  //               ?.copyWith(color: themeExtension.textDimColor),
                  //         ),
                  //       ],
                  //       // TextButton.icon(
                  //       //   onPressed:
                  //       //       _isReacted ? () {} : () => _handleReactPressed(),
                  //       //   onLongPress: _isReacted
                  //       //       ? null
                  //       //       : () {
                  //       //           showModalBottomSheet(
                  //       //             isScrollControlled: true,
                  //       //             useRootNavigator: true,
                  //       //             enableDrag: false,
                  //       //             showDragHandle: true,
                  //       //             useSafeArea: true,
                  //       //             context: context,
                  //       //             builder: (context) {
                  //       //               return EmojiPicker(
                  //       //                 onChanged: (value) {
                  //       //                   Navigator.pop(context);
                  //       //                   _handleReactPressed(value);
                  //       //                 },
                  //       //               );
                  //       //             },
                  //       //           );
                  //       //         },
                  //       //   icon: _emojiUrl == null
                  //       //       ? Icon(
                  //       //           _isReacted
                  //       //               ? Icons.thumb_up
                  //       //               : Icons.thumb_up_outlined,
                  //       //           color: _isReacted
                  //       //               ? themeData.colorScheme.secondary
                  //       //               : themeExtension.textDimColor,
                  //       //         )
                  //       //       : SizedBox(
                  //       //           width: 24,
                  //       //           height: 24,
                  //       //           child: Image(
                  //       //             width: 24,
                  //       //             height: 24,
                  //       //             image: AppUtils.getImageProvider(_emojiUrl!),
                  //       //           ),
                  //       //         ),
                  //       //   style: const ButtonStyle(
                  //       //     padding: WidgetStatePropertyAll(
                  //       //         EdgeInsets.symmetric(vertical: 4, horizontal: 8)),
                  //       //     alignment: Alignment.centerLeft,
                  //       //   ),
                  //       //   label: _reactionCount > 0
                  //       //       ? Text(
                  //       //           NumberFormat.compact().format(_reactionCount),
                  //       //           maxLines: 1,
                  //       //           style: themeData.textTheme.labelMedium
                  //       //               ?.copyWith(
                  //       //                   color: themeExtension.textDimColor),
                  //       //         )
                  //       //       : const SizedBox.shrink(),
                  //       // ),
                  //       // TextButton.icon(
                  //       //   onPressed: () => appState.navigatorPush(
                  //       //     widget: ZapForm(
                  //       //       user: _user!,
                  //       //       event: widget.event,
                  //       //     ),
                  //       //     rootNavigator: true,
                  //       //   ),
                  //       //   icon: Icon(
                  //       //     Icons.electric_bolt,
                  //       //     color: _isZapped
                  //       //         ? Colors.orange
                  //       //         : themeExtension.textDimColor,
                  //       //   ),
                  //       //   style: const ButtonStyle(
                  //       //     padding: WidgetStatePropertyAll(
                  //       //         EdgeInsets.symmetric(
                  //       //             vertical: 4, horizontal: 8)),
                  //       //     alignment: Alignment.centerLeft,
                  //       //   ),
                  //       //   label: _zapCount > 0
                  //       //       ? Text(
                  //       //           NumberFormat.compact().format(_zapCount),
                  //       //           maxLines: 1,
                  //       //           style: themeData.textTheme.labelMedium
                  //       //               ?.copyWith(
                  //       //                   color: themeExtension.textDimColor),
                  //       //         )
                  //       //       : const SizedBox.shrink(),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }
}
