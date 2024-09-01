import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:wherostr_social/models/app_theme.dart';

class AudioPlayer extends StatefulWidget {
  final String url;

  const AudioPlayer({
    super.key,
    required this.url,
  });

  @override
  State createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  final _player = audioplayers.AudioPlayer();
  audioplayers.PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == audioplayers.PlayerState.playing;

  bool get _isPaused => _playerState == audioplayers.PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  @override
  void initState() {
    super.initState();
    // Use initial values from player
    _player.setSource(audioplayers.UrlSource(widget.url));
    _playerState = _player.state;
    _player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    _player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.url,
                style: TextStyle(color: themeExtension.textDimColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _isPlaying ? null : _play,
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(
              onPressed: _isPlaying ? _pause : null,
              icon: const Icon(Icons.pause),
            ),
            IconButton(
              onPressed: _isPlaying || _isPaused ? _stop : null,
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              _positionText,
              style: TextStyle(color: themeExtension.textDimColor),
            ),
            Expanded(
              child: Slider(
                inactiveColor: themeData.colorScheme.surfaceDim,
                onChanged: (value) {
                  final duration = _duration;
                  if (duration == null) {
                    return;
                  }
                  final position = value * duration.inMilliseconds;
                  _player.seek(Duration(milliseconds: position.round()));
                },
                value: (_position != null &&
                        _duration != null &&
                        _position!.inMilliseconds > 0 &&
                        _position!.inMilliseconds < _duration!.inMilliseconds)
                    ? _position!.inMilliseconds / _duration!.inMilliseconds
                    : 0.0,
              ),
            ),
            Text(
              _durationText,
              style: TextStyle(color: themeExtension.textDimColor),
            ),
          ],
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = audioplayers.PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    await _player.resume();
    setState(() => _playerState = audioplayers.PlayerState.playing);
  }

  Future<void> _pause() async {
    await _player.pause();
    setState(() => _playerState = audioplayers.PlayerState.paused);
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() {
      _playerState = audioplayers.PlayerState.stopped;
      _position = Duration.zero;
    });
  }
}
