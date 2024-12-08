import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/widgets/direct_messages_container.dart';
import 'package:wherostr_social/widgets/post_composer.dart';
import 'package:wherostr_social/widgets/post_content.dart';

class MessagesContainer extends StatelessWidget {
  const MessagesContainer({super.key});

  Future<List<DataEvent>> getAllMessages(BuildContext context) async {
    final appState = context.read<AppStatesProvider>();
    const query = '''
    WITH combined AS (
        SELECT *, receiver AS chat_partner
        FROM ${DataMessage.tableName}
        WHERE sender == ?
        UNION
        SELECT *, sender AS chat_partner
        FROM ${DataMessage.tableName}
        WHERE receiver == ?
    ),
    ranked_messages AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY chat_partner 
                ORDER BY created_at DESC
            ) AS rank
        FROM combined
    )
    SELECT 
        *
    FROM ranked_messages
    WHERE rank = 1;
    ''';
    final rows = await DataMessage.database
        .rawQuery(query, [appState.me.pubkey, appState.me.pubkey]);
    return rows.map((e) => DataMessage.fromMap(e).toEvent()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStatesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: FutureBuilder(
        future: getAllMessages(context),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Loading...'),
                    ],
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No items'),
                    ],
                  ),
                );
              } else {
                final event = snapshot.data![index];
                final chatPartner = event.pubkey == appState.me.pubkey
                    ? event.getTagValue('p')!
                    : event.pubkey;
                final composerEvent =
                    DataEvent(pubkey: chatPartner, createdAt: event.createdAt);
                return Material(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          final appState = context.read<AppStatesProvider>();
                          appState.navigatorPush(
                            isBottomNavigationBarVisible: false,
                            widget:
                                DirectMessagesContainer(pubkey: chatPartner),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PostComposer(
                                  event: composerEvent, enableMenu: false),
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
              }
            },
          );
        },
      ),
    );
  }
}
