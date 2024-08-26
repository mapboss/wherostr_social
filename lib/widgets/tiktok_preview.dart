import 'package:flutter/material.dart';

class TiktokPreviewElement extends WidgetSpan {
  final String url;
  TiktokPreviewElement({required this.url})
      : super(child: TiktokPreviewWidget(url: url));
}

class TiktokPreviewWidget extends StatelessWidget {
  final String url;
  const TiktokPreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(url);
  }
}
