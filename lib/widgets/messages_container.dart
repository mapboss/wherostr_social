import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/nips/nip044.dart';
import 'package:wherostr_social/widgets/message_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_content.dart';
import 'package:wherostr_social/widgets/post_details.dart';

class MessagesContainer extends StatelessWidget {
  const MessagesContainer({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, bool> events = {};
    ThemeData themeData = Theme.of(context);
    final appState = context.read<AppStatesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: NostrFeed(
        backgroundColor: themeData.colorScheme.primary.withOpacity(0.054),
        scrollController: ScrollController(),
        relays: appState.me.relayList.clone(),
        kinds: const [1059],
        p: [appState.me.pubkey],
        itemMapper: (e) async {
          final keyPairs = await AppSecret.read();
          if (e.kind == 1059) {
            final json = await Nip44.decrypt(
                e.content!, Nip44.shareSecret(keyPairs!.private, e.pubkey));
            return DataEvent.fromJson(jsonDecode(json));
          }
          return e;
        },
        itemFilter: (e) {
          if (e.kind != 4 && e.kind != 13) return false;
          if (events.containsKey(e.pubkey)) return false;
          if (e.pubkey == appState.me.pubkey) return false;
          events[e.pubkey] = true;
          return true;
        },
        itemBuilder: (context, event) {
          final content = getEllipsisText(
            text: event.content!,
            maxWidth:
                (MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth
                        ? Constants.largeDisplayContentWidth
                        : MediaQuery.sizeOf(context).width) -
                    76,
            maxLines: 3,
          );
          return Material(
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    final appState = context.read<AppStatesProvider>();
                    appState.navigatorPush(
                      widget: Scaffold(
                        appBar: AppBar(
                          title: const Text('Chat'),
                        ),
                        body: NostrFeed(
                          backgroundColor:
                              themeData.colorScheme.primary.withOpacity(0.054),
                          scrollController: ScrollController(),
                          relays: appState.me.relayList.clone(),
                          kinds: const [4, 1059],
                          //authors: [event.pubkey, appState.me.pubkey],
                          p: [appState.me.pubkey],
                          autoRefresh: true,
                          reverse: true,
                          isDynamicHeight: true,
                          itemMapper: (e) async {
                            final keyPairs = await AppSecret.read();
                            if (e.kind == 1059) {
                              return Nip17.decode(e, keyPairs!.private);
                            }
                            final msg = await Nip4.decode(
                                e, keyPairs!.public, keyPairs.private);
                            e.content = msg?.content;
                            return e;
                          },
                          itemFilter: (e) {
                            if (e.kind != 4 && e.kind != 14) return false;
                            if (e.pubkey != event.pubkey &&
                                e.pubkey != appState.me.pubkey) return false;
                            return true;
                          },
                          itemBuilder: (context, event) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: MessageItem(
                              event: event,
                              isCompact: false,
                              enableActionBar: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostComposer(event: event, enableMenu: false),
                        PostContent(
                          content: content.trim(),
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
      ),
    );
  }
}

String getEllipsisText({
  required String text,
  required double maxWidth,
  required int maxLines,
  TextStyle? style,
  String? ellipsisText = '...',
}) {
  TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: style,
    ),
    maxLines: maxLines,
    textDirection: ui.TextDirection.ltr,
  );
  textPainter.layout(maxWidth: maxWidth);
  if (!textPainter.didExceedMaxLines) {
    return text;
  }
  final textSize = textPainter.size;
  final ellipsisTextPainter = TextPainter(
    text: TextSpan(
      text: ellipsisText,
      style: style,
    ),
    maxLines: maxLines,
    textDirection: ui.TextDirection.ltr,
  );
  ellipsisTextPainter.layout(maxWidth: maxWidth);
  final ellipsisWidth = ellipsisTextPainter.size.width;
  if (textPainter.didExceedMaxLines &&
      textSize.width + ellipsisWidth > maxWidth) {
    final textOffsetPosition = textPainter.getOffsetBefore(textPainter
            .getPositionForOffset(
                Offset(textSize.width - ellipsisWidth, textSize.height))
            .offset) ??
        0;
    return '${text.substring(0, textOffsetPosition)}$ellipsisText';
  } else {
    return text;
  }
}
