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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification center'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(
                icon: Icon(Icons.repeat),
              ),
              Tab(
                icon: Icon(Icons.comment_outlined),
              ),
              Tab(
                icon: Icon(Icons.thumb_up),
              ),
              Tab(
                icon: Icon(Icons.electric_bolt),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            [1, 6, 7, 9735],
            [6],
            [1],
            [7],
            [9735],
          ]
              .map(
                (kind) => NostrFeed(
                  relays: appState.me.relayList.clone(),
                  includeReplies: true,
                  kinds: kind,
                  p: [appState.me.pubkey],
                  itemFilter: (event) => event.pubkey != appState.me.pubkey,
                  itemBuilder: (context, event) => Material(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ActivityItem(
                            event: event,
                            enableTap: true,
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
              )
              .toList(),
        ),
      ),
    );
  }
}
