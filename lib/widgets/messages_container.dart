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

  Future<List<DataEvent>> getAllMessages() async {
    final rows = await DataMessage.database.query(
      DataMessage.tableName,
      groupBy: 'sender',
      orderBy: 'created_at DESC',
    );
    return rows.map((e) => DataMessage.fromMap(e).toEvent()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: FutureBuilder(
        future: getAllMessages(),
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
                return Material(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          final appState = context.read<AppStatesProvider>();
                          appState.navigatorPush(
                            isBottomNavigationBarVisible: false,
                            widget:
                                DirectMessagesContainer(pubkey: event.pubkey),
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
              }
            },
          );
        },
      ),
    );
  }
}
