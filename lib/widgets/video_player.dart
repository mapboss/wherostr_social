import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart' as _;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';

class VideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final BoxConstraints? constraints;

  const VideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.constraints,
  });

  @override
  State createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  OverlayEntry? _overlayEntry;
  late _.VideoPlayerController _controller;
  final _visibilityDetectorKey = UniqueKey();
  bool _showController = true;
  bool _isFullscreen = false;
  late bool _isLiveStream;

  @override
  void initState() {
    super.initState();
    initVideo();
  }

  void initVideo() {
    final uri = Uri.parse(widget.url);
    setState(() {
      _isLiveStream = uri.path.toLowerCase().endsWith('.m3u8');
    });
    _controller = _.VideoPlayerController.networkUrl(uri);
    _controller.addListener(controllerListener);
    _controller.initialize().then((_) {
      if (widget.autoPlay) {
        _controller.play();
        toggleShowController(false);
      }
      setState(() {});
    });
    if (_isLiveStream) {
      checkIsEnded(uri);
    }
  }

  void checkIsEnded(Uri uri, [bool recursive = true]) async {
    try {
      final response = await http.get(uri);
      final playList =
          await HlsPlaylistParser.create().parseString(uri, response.body);
      if (playList is HlsMasterPlaylist) {
        final mediaUri = playList.mediaPlaylistUrls.lastOrNull;
        if (mediaUri != null && recursive) {
          checkIsEnded(mediaUri, false);
        }
      } else if (playList is HlsMediaPlaylist) {
        if (playList.hasEndTag) {
          setState(() {
            _isLiveStream = false;
          });
        }
      }
    } catch (error) {}
  }

  void controllerListener() {
    WakelockPlus.enabled.then((enabled) {
      if (enabled && !_controller.value.isPlaying) {
        WakelockPlus.disable();
      } else if (!enabled && _controller.value.isPlaying) {
        WakelockPlus.enable();
      }
    });
    if (!_controller.value.isPlaying &&
        !_controller.value.isBuffering &&
        _controller.value.isCompleted) {
      toggleShowController(true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(controllerListener);
    _controller.dispose();
    _removeOverlay();
    WakelockPlus.disable();
    super.dispose();
  }

  void updateOverlayState() {
    if (_isFullscreen) {
      Overlay.of(context, rootOverlay: true).setState(() {});
    }
  }

  void toggleShowController([bool? value]) {
    setState(() {
      _showController = value ?? !_showController;
      updateOverlayState();
    });
  }

  void setIsFullScreen(bool isFullscreen) {
    if (isFullscreen) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
    setState(() {
      _isFullscreen = isFullscreen;
    });
  }

  void seekBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  void seekForward() {
    final currentPosition = _controller.value.position;
    final videoDuration = _controller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);
    if (newPosition <= videoDuration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(videoDuration);
    }
  }

  void togglePlay([bool? value]) {
    setState(() {
      if (value ?? !_controller.value.isPlaying) {
        if (_isLiveStream) {
          _controller.removeListener(controllerListener);
          _controller.dispose();
          initVideo();
        } else {
          _controller.play().then((_) => setState(() {
                _showController = false;
              }));
        }
      } else {
        _controller.pause();
      }
    });
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        ThemeData themeData = Theme.of(context);
        final isLargeDisplay =
            MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth;
        final isLandscape =
            isLargeDisplay ? false : _controller.value.aspectRatio >= (3 / 2);
        return Positioned.fill(
          child: Dismissible(
            key: const Key('video-full-screen-overlay'),
            direction: isLandscape
                ? DismissDirection.endToStart
                : DismissDirection.down,
            onDismissed: (_) => setIsFullScreen(false),
            child: Container(
              color: themeData.colorScheme.surface,
              child: SafeArea(
                child: NativeDeviceOrientationReader(
                  builder: (context) => RotatedBox(
                    quarterTurns: isLandscape
                        ? NativeDeviceOrientationReader.orientation(context) ==
                                NativeDeviceOrientation.landscapeLeft
                            ? 3
                            : 1
                        : 0,
                    child: _buildWidget(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildWidget() {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, _.VideoPlayerValue value, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: value.isInitialized ? () => toggleShowController() : null,
          child: Container(
            color: themeData.colorScheme.surface,
            child: Stack(
              children: [
                Positioned.fill(
                  child: value.errorDescription == null
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: value.aspectRatio,
                            child: VisibilityDetector(
                              key: _visibilityDetectorKey,
                              onVisibilityChanged: (visibilityInfo) {
                                if (visibilityInfo.visibleFraction < 0.25) {
                                  _controller.pause().then((_) => setState(() {
                                        _showController = true;
                                      }));
                                }
                              },
                              child: _.VideoPlayer(_controller),
                            ),
                          ),
                        )
                      : Container(
                          color: themeData.colorScheme.surfaceDim,
                        ),
                ),
                if (value.isInitialized)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showController ? 1 : 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.38),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_isLiveStream)
                                    IconButton(
                                      color: Colors.white,
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.black.withOpacity(0.38),
                                      ),
                                      onPressed: _showController
                                          ? () => seekBackward()
                                          : null,
                                      icon: const Icon(Icons.replay_10),
                                    ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    color: Colors.white,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.black.withOpacity(0.38),
                                    ),
                                    onPressed: _showController
                                        ? () => togglePlay()
                                        : null,
                                    icon: Icon(
                                      value.isPlaying
                                          ? Icons.pause
                                          : value.isCompleted && !_isLiveStream
                                              ? Icons.replay
                                              : Icons.play_arrow,
                                    ),
                                    iconSize: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  if (!_isLiveStream)
                                    IconButton(
                                      color: Colors.white,
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.black.withOpacity(0.38),
                                      ),
                                      onPressed: _showController
                                          ? () => seekForward()
                                          : null,
                                      icon: const Icon(Icons.forward_10),
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: () =>
                                    launchUrl(Uri.parse(widget.url)),
                                icon: const Icon(Icons.open_in_new),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  if (!_isLiveStream)
                                    Text(
                                      '${formatDuration(value.position)} / ${formatDuration(value.duration)}',
                                      style: themeData.textTheme.bodySmall,
                                    ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _showController
                                        ? setIsFullScreen(!_isFullscreen)
                                        : null,
                                    icon: Icon(
                                      _isFullscreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (value.errorDescription == null)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppUtils.statusIcon(
                                    context: context,
                                    status: AppStatus.warning),
                                const SizedBox(width: 4),
                                Text(
                                  'Unable to load the video',
                                  style: TextStyle(
                                    color: themeExtension.textDimColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              child: IntrinsicWidth(
                                child: Row(
                                  children: [
                                    const Icon(Icons.link),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.url,
                                        style: TextStyle(
                                          color: themeExtension.textDimColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => launchUrl(
                                Uri.parse(widget.url),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                if (value.errorDescription == null) ...[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: _showController ? 12 : 0,
                    right: _showController ? 12 : 0,
                    bottom: _showController ? 10 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showController ? 1 : 0.54,
                      child: _.VideoProgressIndicator(
                        _controller,
                        allowScrubbing: false,
                        colors: _.VideoProgressColors(
                          playedColor:
                              themeData.colorScheme.primary.withOpacity(0.87),
                          bufferedColor:
                              themeData.colorScheme.secondary.withOpacity(0.54),
                        ),
                      ),
                    ),
                  ),
                  if (!_isLiveStream)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      left: _showController ? 4 : -8,
                      right: _showController ? 4 : -8,
                      bottom: _showController ? 4 : -8,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showController ? 1 : 0,
                        child: CustomVideoProgressIndicator(
                          controller: _controller,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.constraints,
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: _controller.value.isInitialized &&
                  _controller.value.errorDescription == null
              ? _controller.value.aspectRatio
              : 16 / 9,
          child: _isFullscreen ? const SizedBox.shrink() : _buildWidget(),
        ),
      ),
    );
  }
}

class CustomVideoProgressIndicator extends StatefulWidget {
  final _.VideoPlayerController controller;

  const CustomVideoProgressIndicator({super.key, required this.controller});

  @override
  State createState() => _CustomVideoProgressIndicatorState();
}

class _CustomVideoProgressIndicatorState
    extends State<CustomVideoProgressIndicator> {
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentPosition =
        widget.controller.value.position.inMilliseconds.toDouble();
    widget.controller.addListener(controllerListener);
  }

  void controllerListener() {
    setState(() {
      _currentPosition =
          widget.controller.value.position.inMilliseconds.toDouble();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: widget.controller.value.isInitialized
          ? SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                thumbColor: themeData.colorScheme.primary,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: _currentPosition,
                min: 0,
                max: widget.controller.value.duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _currentPosition = value;
                  });
                },
                onChangeEnd: (value) {
                  widget.controller
                      .seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
