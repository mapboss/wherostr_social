// NIP-75: Zap Goal => https://github.com/nostr-protocol/nips/blob/master/75.md
// UI: https://heya.fund/

import 'package:flutter/material.dart';
import 'package:wherostr_social/models/data_event.dart';

class PostZapGoal extends StatefulWidget {
  final DataEvent? event;
  final String? eventId;
  const PostZapGoal({super.key, this.event, this.eventId});

  @override
  State createState() => _PostZapGoalState();
}

class _PostZapGoalState extends State<PostZapGoal> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('Sorry, we currently do not support this post type.'),
      ),
    );
  }
}
