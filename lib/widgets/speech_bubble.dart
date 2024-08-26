import 'package:flutter/material.dart';

enum SpeechBubbleOrigin { left, right }

class CSpeechBubble extends StatefulWidget {
  final Widget? child;
  final SpeechBubbleOrigin origin;
  const CSpeechBubble(
      {super.key, this.child, this.origin = SpeechBubbleOrigin.left});
  @override
  State createState() => _CSpeechBubbleState();
}

class _CSpeechBubbleState extends State<CSpeechBubble> {
  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: SpeechBubbleClipper(origin: widget.origin),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

// Scaffold(
//   body: Container(
//     margin: const EdgeInsets.all(16),
//     child: ListView(
//       children: [
//         const Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Flexible(
//               child: CSpeechBubble(
//                 origin: SpeechBubbleOrigin.right,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text('Hi!'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Flexible(
//               child: CSpeechBubble(
//                 origin: SpeechBubbleOrigin.right,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text('Hi!'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Flexible(
//               child: CSpeechBubble(
//                 origin: SpeechBubbleOrigin.left,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Hi!'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Flexible(
//               child: CSpeechBubble(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Hi!'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         // const Row(
//         //   mainAxisAlignment: MainAxisAlignment.start,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.start,
//         //           children: [
//         //             AudioPlayer(
//         //                 url:
//         //                     '.mp3'),
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // const Row(
//         //   mainAxisAlignment: MainAxisAlignment.end,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         origin: SpeechBubbleOrigin.right,
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.end,
//         //           children: [
//         //             AudioPlayer(
//         //                 url:
//         //                     '.mp3'),
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // Row(
//         //   mainAxisAlignment: MainAxisAlignment.start,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.start,
//         //           children: [
//         //             Container(
//         //               constraints: const BoxConstraints(
//         //                 maxHeight: 340,
//         //                 minWidth: 170,
//         //               ),
//         //               child: const AspectRatio(
//         //                 aspectRatio: 1,
//         //                 child: PhotoView(
//         //                     url:
//         //                         '.jpg'),
//         //               ),
//         //             ),
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // Row(
//         //   mainAxisAlignment: MainAxisAlignment.start,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.start,
//         //           children: [
//         //             SizedBox(
//         //               height: 120,
//         //               child: CImageGallery(
//         //                   url:
//         //                       '.jpg'),
//         //             )
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // Row(
//         //   mainAxisAlignment: MainAxisAlignment.end,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         origin: SpeechBubbleOrigin.right,
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.end,
//         //           children: [
//         //             CImageGallery(
//         //                 url:
//         //                     '.jpg'),
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // const Row(
//         //   mainAxisAlignment: MainAxisAlignment.start,
//         //   children: [
//         //     Flexible(
//         //       child: CSpeechBubble(
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.start,
//         //           children: [
//         //             SizedBox(
//         //               height: 120,
//         //               child: VideoPlayer(
//         //                   url:
//         //                       '.mp4'),
//         //             )
//         //           ],
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//       ],
//     ),
//   ),
// );
