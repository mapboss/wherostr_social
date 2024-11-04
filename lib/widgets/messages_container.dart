import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/widgets/message_item.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_content.dart';

class MessagesContainer extends StatelessWidget {
  const MessagesContainer({super.key});

  Future<List<DataEvent>> getAllMessages() async {
    final rows = await DataMessage.database.query(DataMessage.tableName,
        groupBy: 'sender', orderBy: 'created_at DESC');
    return rows.map((e) => DataMessage.fromMap(e).toEvent()).toList();
  }

  Future<List<DataEvent>> getDirectMessages(String sender) async {
    final rows = await DataMessage.database.query(DataMessage.tableName,
        orderBy: 'created_at DESC',
        where: "sender = '$sender' or reciever = '$sender'");
    return rows.map((e) {
      return DataMessage.fromMap(e).toEvent();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAllMessages(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages'),
          ),
          body: ListView.builder(
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
              return Material(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        final appState = context.read<AppStatesProvider>();
                        appState.navigatorPush(
                          widget: FutureBuilder(
                            future: getDirectMessages(event.pubkey),
                            builder: (context, snapshot) {
                              return Scaffold(
                                appBar: AppBar(
                                  title: const Text('Messages'),
                                ),
                                body: ListView.builder(
                                  reverse: true,
                                  itemCount: snapshot.data?.length,
                                  itemBuilder: (context, index) {
                                    if (snapshot.data == null) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('No items'),
                                          ],
                                        ),
                                      );
                                    }
                                    final event = snapshot.data![index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 12),
                                      child: MessageItem(
                                        event: event,
                                        isCompact: false,
                                        enableActionBar: true,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
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
          ),
        );
      },
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
