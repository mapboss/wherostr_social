import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/widgets/message_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';
// import 'package:wherostr_social/widgets/post_compose.dart';
import 'package:wherostr_social/widgets/video_player.dart';

class LiveActivity extends StatefulWidget {
  final NostrEvent event;

  const LiveActivity({
    super.key,
    required this.event,
  });

  @override
  State<LiveActivity> createState() => _LiveActivityState();
}

class _LiveActivityState extends State<LiveActivity> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final appState = context.watch<AppStatesProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayer(url: 'mp4'),
            ),
            Expanded(
              child: NostrFeed(
                backgroundColor:
                    themeData.colorScheme.primary.withOpacity(0.054),
                scrollController: ScrollController(),
                relays: appState.me.relayList.clone(),
                kinds: const [9735, 1311],
                a: [getNostrAddress(widget.event)],
                autoRefresh: true,
                reverse: true,
                isDynamicHeight: true,
                itemBuilder: (context, event) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: MessageItem(
                    event: event,
                    isCompact: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  filled: true,
                  fillColor: themeData.colorScheme.surfaceDim,
                  prefixIcon: const Icon(Icons.comment_outlined),
                  hintText: 'Add a reply',
                ),
                readOnly: true,
                // onTap: () => appState.navigatorPush(
                //   widget: PostCompose(
                //     referencedEvent: _event,
                //     isReply: true,
                //   ),
                //   rootNavigator: true,
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
