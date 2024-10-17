import 'package:flutter/material.dart';
import 'package:wherostr_social/models/data_event.dart';

class PostUnsupportedType extends StatelessWidget {
  final DataEvent event;

  const PostUnsupportedType({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Sorry, we currently do not support this post type.'),
          Text('Kind: ${event.kind}'),
        ],
      ),
    );
  }
}
