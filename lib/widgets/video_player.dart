import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wherostr_social/widgets/custom_flick_video_player.dart';

class VideoPlayer extends StatefulWidget {
  final String url;
  const VideoPlayer({super.key, required this.url});
  @override
  State createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late FlickManager _flickManager;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _flickManager = FlickManager(
      videoPlayerController:
          VideoPlayerController.networkUrl(Uri.parse(widget.url)),
      autoPlay: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomFlickVideoPlayer(
      flickManager: _flickManager,
      flickVideoWithControls: const FlickVideoWithControls(
        videoFit: BoxFit.contain,
        controls: FlickPortraitControls(
          iconSize: 40,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flickManager.dispose();
    super.dispose();
  }
}
