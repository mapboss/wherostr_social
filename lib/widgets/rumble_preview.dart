import 'package:flutter/material.dart';

class RumblePreviewElement extends WidgetSpan {
  final String url;
  RumblePreviewElement({required this.url})
      : super(child: RumblePreviewWidget(url: url));
}

class RumblePreviewWidget extends StatelessWidget {
  final String url;
  const RumblePreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(url);
  }
}
