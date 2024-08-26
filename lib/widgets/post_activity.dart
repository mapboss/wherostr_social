import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/widgets/activity_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';

class PostActivity extends StatelessWidget {
  final NostrEvent event;

  const PostActivity({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final relayList = context.read<AppStatesProvider>().me.relayList.clone();
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Post activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reposts'),
              Tab(text: 'Reactions'),
              Tab(text: 'Zaps'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NostrFeed(
              relays: relayList,
              kinds: const [6],
              e: [event.id!],
              autoRefresh: true,
              itemBuilder: (context, event) => Material(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ActivityItem(event: event),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),
            NostrFeed(
              relays: relayList,
              kinds: const [7],
              e: [event.id!],
              autoRefresh: true,
              itemBuilder: (context, event) => Material(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ActivityItem(event: event),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),
            NostrFeed(
              relays: relayList,
              kinds: const [9735],
              e: [event.id!],
              autoRefresh: true,
              itemBuilder: (context, event) => Material(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ActivityItem(event: event),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
