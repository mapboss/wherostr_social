import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/widgets/activity_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';

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
        kinds: const [4, 1059],
        autoRefresh: true,
        p: [appState.me.pubkey],
        isDynamicHeight: true,
        itemFilter: (e) {
          if (events.containsKey(e.pubkey)) return false;
          events[e.pubkey] = true;
          return true;
        },
        itemMapper: (e) async {
          final keyPairs = await AppSecret.read();
          if (e.kind == 1059) {
            return Nip17.decode(e, keyPairs!.private);
          }
          return e;
        },
        itemBuilder: (context, event) {
          return Material(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => print('Tab: ${event.id}'),
                    child: ActivityItem(
                      event: event,
                      enableTap: false,
                      showIcon: false,
                      showCreatedAt: true,
                      showFollowButton: false,
                      showReferencedEvent: true,
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
