import 'package:flutter/material.dart';

class TwitchPreviewElement extends WidgetSpan {
  final String url;
  TwitchPreviewElement({required this.url})
      : super(child: TwitchPreviewWidget(url: url));
}

class TwitchPreviewWidget extends StatelessWidget {
  final String url;
  const TwitchPreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(url);
  }
}
