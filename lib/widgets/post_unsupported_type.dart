import 'package:flutter/material.dart';

class PostUnsupportedType extends StatelessWidget {
  const PostUnsupportedType({super.key});

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
