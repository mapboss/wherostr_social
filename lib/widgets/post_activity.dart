import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/widgets/activity_item.dart';
import 'package:wherostr_social/widgets/nostr_feed.dart';

class PostActivity extends StatelessWidget {
  final DataEvent event;

  const PostActivity({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final relayList = context.read<AppStatesProvider>().me.relayList.clone();
    final kind = event.kind!;
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
              kinds: [kind == 1 ? 6 : 16],
              e: kind >= 30000 && kind < 40000 ? null : [event.id!],
              a: kind >= 30000 && kind < 40000 ? [event.getAddressId()!] : null,
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
              e: kind >= 30000 && kind < 40000 ? null : [event.id!],
              a: kind >= 30000 && kind < 40000 ? [event.getAddressId()!] : null,
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
              e: kind >= 30000 && kind < 40000 ? null : [event.id!],
              a: kind >= 30000 && kind < 40000 ? [event.getAddressId()!] : null,
              autoRefresh: true,
              isDynamicHeight: true,
              disableLimit: true,
              itemSorting: (a, b) {
                String? descA = a.getTagValue('bolt11');
                String? descB = b.getTagValue('bolt11');
                final boltB = Bolt11PaymentRequest(descB!);
                return boltB.amount
                    .compareTo(Bolt11PaymentRequest(descA!).amount);
              },
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
