import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HttpUrlDisplayElement extends TextSpan {
  HttpUrlDisplayElement({
    required String text,
    super.style,
    bool enableElementTap = true,
    TextDecoration decoration = TextDecoration.none,
  }) : super(
            text: text.length > 28 ? '${text.substring(0, 28)}...' : text,
            recognizer: TapGestureRecognizer()
              ..onTap =
                  enableElementTap ? () => launchUrl(Uri.parse(text)) : null);
}
