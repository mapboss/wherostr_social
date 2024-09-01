import 'package:flutter/material.dart';

enum SpeechBubbleOrigin {
  left,
  right,
}

class SpeechBubble extends StatefulWidget {
  final Widget child;
  final SpeechBubbleOrigin origin;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const SpeechBubble({
    super.key,
    required this.child,
    this.origin = SpeechBubbleOrigin.left,
    this.padding,
    this.color,
  });

  @override
  State createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return PhysicalShape(
      clipper: SpeechBubbleClipper(origin: widget.origin),
      color: widget.color ?? themeData.colorScheme.surface,
      child: Padding(
        padding: widget.padding ??
            const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: widget.child,
      ),
    );
  }
}

class SpeechBubbleClipper extends CustomClipper<Path> {
  final double radius = 12;
  final double horizontalPadding = 8;
  final SpeechBubbleOrigin origin;

  SpeechBubbleClipper({required this.origin});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRRect(
      RRect.fromLTRBR(horizontalPadding, 0, size.width - horizontalPadding,
          size.height, Radius.circular(radius)),
    );
    switch (origin) {
      case SpeechBubbleOrigin.left:
        final path2 = Path();
        path2.arcToPoint(Offset(horizontalPadding * 2, 0),
            radius: Radius.circular(radius), clockwise: false);
        path2.lineTo(horizontalPadding, radius);
        path2.arcToPoint(const Offset(0, 0), radius: Radius.circular(radius));
        path.addPath(path2, const Offset(0, 0));
        break;
      case SpeechBubbleOrigin.right:
        final path2 = Path();
        path2.arcToPoint(Offset(horizontalPadding * 2, 0),
            radius: Radius.circular(radius), clockwise: false);
        path2.arcToPoint(Offset(horizontalPadding, radius),
            radius: Radius.circular(radius));
        path.addPath(path2, Offset(size.width - (horizontalPadding * 2), 0));
        break;
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
