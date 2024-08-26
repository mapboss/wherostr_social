import 'package:flutter/material.dart';

class FacebookPreviewElement extends WidgetSpan {
  final String url;
  FacebookPreviewElement({required this.url})
      : super(child: FacebookPreviewWidget(url: url));
}

class FacebookPreviewWidget extends StatelessWidget {
  final String url;
  const FacebookPreviewWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Text(url);
  }
}
