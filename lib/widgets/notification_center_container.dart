import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/widgets/activity_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';

class NotificationCenterContainer extends StatelessWidget {
  const NotificationCenterContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStatesProvider>();
    final feedKey = GlobalKey<NostrFeedState>();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: GestureDetector(
          onTap: () => feedKey.currentState?.scrollToFirstItem(),
        ),
        title: GestureDetector(
          onTap: () => feedKey.currentState?.scrollToFirstItem(),
          child: const Text('Notification center'),
        ),
      ),
      body: NostrFeed(
        key: feedKey,
        relays: appState.me.relayList.clone(),
        includeReplies: true,
        kinds: const [1, 6, 7, 9735],
        p: [appState.me.pubkey],
        itemFilter: (event) => event.pubkey != appState.me.pubkey,
        itemBuilder: (context, event) => Material(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ActivityItem(
                  event: event,
                  enableViewReferencedEventTap: true,
                  showCreatedAt: true,
                  showFollowButton: false,
                  showReferencedEvent: true,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
