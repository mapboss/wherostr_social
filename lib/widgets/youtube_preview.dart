import 'package:flutter/material.dart';

class YoutubePreviewElement extends WidgetSpan {
  final String url;
  YoutubePreviewElement({required this.url})
      : super(child: YoutubePreviewWidget(url: url));
}

class YoutubePreviewWidget extends StatelessWidget {
  final String url;
  const YoutubePreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(url);
  }
}
