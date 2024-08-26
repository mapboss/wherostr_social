import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;

class AudioPlayer extends StatefulWidget {
  final String url;
  const AudioPlayer({super.key, required this.url});
  @override
  State createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  final _player = audioplayers.AudioPlayer();
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        if (_isPlaying) {
          await _player.stop();
        } else {
          await _player.play(audioplayers.UrlSource(widget.url));
        }
        setState(() {
          _isPlaying = !_isPlaying;
        });
      },
      child: Text(_isPlaying ? 'Stop' : 'Play'),
    );
  }
}
