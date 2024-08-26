import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';

class LinkPreview extends StatelessWidget {
  final String url;
  const LinkPreview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AnyLinkPreview(
      link: url,
    );
  }
}
