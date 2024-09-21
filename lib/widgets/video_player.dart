import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart' as _;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/utils/formatter.dart';

class VideoPlayer extends StatefulWidget {
  final String url;
  const VideoPlayer({super.key, required this.url});
  @override
  State createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  OverlayEntry? _overlayEntry;
  late _.VideoPlayerController _controller;
  final _visibilityDetectorKey = UniqueKey();
  bool _showController = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = _.VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _removeOverlay();
    WakelockPlus.disable();
    super.dispose();
  }

  void setShowController(bool showController) {
    setState(() {
      _showController = showController;
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

  void togglePlay() {
    setState(() {
      _controller.value.isPlaying
          ? _controller.pause().then((_) => WakelockPlus.disable())
          : _controller.play().then((_) => setState(() {
                WakelockPlus.enable();
                _showController = false;
              }));
    });
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: SafeArea(
          child: RotatedBox(
            quarterTurns: _controller.value.aspectRatio > 1 ? 1 : 0,
            child: _buildWidget(),
          ),
        ),
      ),
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
      builder: (context, _.VideoPlayerValue value, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setShowController(!_showController),
        child: Container(
          color: themeData.colorScheme.surface,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VisibilityDetector(
                      key: _visibilityDetectorKey,
                      onVisibilityChanged: (visibilityInfo) {
                        if (visibilityInfo.visibleFraction < 0.25) {
                          _controller.pause().then((_) => setState(() {
                                WakelockPlus.disable();
                                _showController = true;
                              }));
                        }
                      },
                      child: _.VideoPlayer(_controller),
                    ),
                  ),
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
                                        : Icons.play_arrow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => launchUrl(Uri.parse(widget.url)),
                              icon: const Icon(Icons.open_in_new),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
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
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppUtils.statusIcon(
                                context: context, status: AppStatus.warning),
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
                          onTap: () => launchUrl(
                            Uri.parse(widget.url),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              if (value.errorDescription == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _.VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: _.VideoProgressColors(
                      playedColor:
                          themeData.colorScheme.secondary.withOpacity(0.54),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isFullscreen ? const SizedBox.shrink() : _buildWidget();
  }
}
