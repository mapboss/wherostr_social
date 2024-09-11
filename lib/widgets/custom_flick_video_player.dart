import 'package:provider/provider.dart';
import 'package:universal_html/html.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wherostr_social/models/app_states.dart';

void flickDefaultWebKeyDownHandler(
    KeyboardEvent event, FlickManager flickManager) {
  if (event.keyCode == 70) {
    flickManager.flickControlManager?.toggleFullscreen();
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 77) {
    flickManager.flickControlManager?.toggleMute();
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 39) {
    flickManager.flickControlManager?.seekForward(const Duration(seconds: 10));
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 37) {
    flickManager.flickControlManager?.seekBackward(const Duration(seconds: 10));
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 32) {
    flickManager.flickControlManager?.togglePlay();
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 38) {
    flickManager.flickControlManager?.increaseVolume(0.05);
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  } else if (event.keyCode == 40) {
    flickManager.flickControlManager?.decreaseVolume(0.05);
    flickManager.flickDisplayManager?.handleShowPlayerControls();
  }
}

class CustomFlickVideoPlayer extends StatefulWidget {
  const CustomFlickVideoPlayer({
    super.key,
    required this.flickManager,
    this.flickVideoWithControls = const FlickVideoWithControls(
      controls: FlickPortraitControls(),
    ),
    this.flickVideoWithControlsFullscreen,
    this.systemUIOverlay = SystemUiOverlay.values,
    this.systemUIOverlayFullscreen = const [],
    this.preferredDeviceOrientation = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.preferredDeviceOrientationFullscreen = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ],
    this.wakelockEnabled = true,
    this.wakelockEnabledFullscreen = true,
    this.webKeyDownHandler = flickDefaultWebKeyDownHandler,
  });

  final FlickManager flickManager;

  /// Widget to render video and controls.
  final Widget flickVideoWithControls;

  /// Widget to render video and controls in full-screen.
  final Widget? flickVideoWithControlsFullscreen;

  /// SystemUIOverlay to show.
  ///
  /// SystemUIOverlay is changed in init.
  final List<SystemUiOverlay> systemUIOverlay;

  /// SystemUIOverlay to show in full-screen.
  final List<SystemUiOverlay> systemUIOverlayFullscreen;

  /// Preferred device orientation.
  ///
  /// Use [preferredDeviceOrientationFullscreen] to manage orientation for full-screen.
  final List<DeviceOrientation> preferredDeviceOrientation;

  /// Preferred device orientation in full-screen.
  final List<DeviceOrientation> preferredDeviceOrientationFullscreen;

  /// Prevents the screen from turning off automatically.
  ///
  /// Use [wakeLockEnabledFullscreen] to manage wakelock for full-screen.
  final bool wakelockEnabled;

  /// Prevents the screen from turning off automatically in full-screen.
  final bool wakelockEnabledFullscreen;

  /// Callback called on keyDown for web, used for keyboard shortcuts.
  final Function(KeyboardEvent, FlickManager) webKeyDownHandler;

  @override
  createState() => _CustomFlickVideoPlayerState();
}

class _CustomFlickVideoPlayerState extends State<CustomFlickVideoPlayer>
    with WidgetsBindingObserver {
  late FlickManager flickManager;
  final _visibilityDetectorKey = UniqueKey();
  bool _isFullscreen = false;
  double? _videoWidth;
  double? _videoHeight;
  bool _isShowModal = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    flickManager = widget.flickManager;

    // Register context and perform initialization in post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flickManager.registerContext(context);
      _initializeFlickManager();
    });
  }

  void _initializeFlickManager() {
    flickManager.flickControlManager!.addListener(listener);
    _setSystemUIOverlays();
    _setPreferredOrientation();

    if (widget.wakelockEnabled) {
      WakelockPlus.enable();
    }

    if (kIsWeb) {
      document.documentElement?.onFullscreenChange
          .listen(_webFullscreenListener);
      document.documentElement?.onKeyDown.listen(_webKeyListener);
    }
  }

  @override
  void dispose() {
    flickManager.flickControlManager!.removeListener(listener);
    if (widget.wakelockEnabled) {
      WakelockPlus.disable();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (flickManager.flickControlManager!.isFullscreen) {
      flickManager.flickControlManager!.exitFullscreen();
      return true;
    }
    return false;
  }

  // Listener on [FlickControlManager],
  // Pushes the full-screen if [FlickControlManager] is changed to full-screen.
  void listener() async {
    if (flickManager.flickControlManager!.isFullscreen && !_isFullscreen) {
      _switchToFullscreen();
    } else if (_isFullscreen &&
        !flickManager.flickControlManager!.isFullscreen) {
      _exitFullscreen();
    }
  }

  _switchToFullscreen() {
    if (widget.wakelockEnabledFullscreen) {
      /// Disable previous wakelock setting.
      WakelockPlus.disable();
      WakelockPlus.enable();
    }

    _isFullscreen = true;
    _setPreferredOrientation();
    _setSystemUIOverlays();
    if (kIsWeb) {
      document.documentElement?.requestFullscreen();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _videoHeight = MediaQuery.sizeOf(context).height;
          _videoWidth = MediaQuery.sizeOf(context).width;
          setState(() {});
        }
      });
    } else {
      _isShowModal = true;
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) {
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 1,
              child: FlickManagerBuilder(
                flickManager: flickManager,
                child: widget.flickVideoWithControlsFullscreen ??
                    widget.flickVideoWithControls,
              ),
            ),
          );
        },
      ).whenComplete(() {
        _isShowModal = false;
        if (flickManager.flickControlManager!.isFullscreen) {
          flickManager.flickControlManager!.exitFullscreen();
        }
      });
    }
  }

  _exitFullscreen() {
    if (widget.wakelockEnabled) {
      /// Disable previous wakelock setting.
      WakelockPlus.disable();
      WakelockPlus.enable();
    }

    _isFullscreen = false;

    if (kIsWeb) {
      document.exitFullscreen();
      _videoHeight = null;
      _videoWidth = null;
      setState(() {});
    } else if (_isShowModal) {
      context.read<AppStatesProvider>().navigatorPop();
    }
    _setPreferredOrientation();
    _setSystemUIOverlays();
  }

  _setPreferredOrientation() {
    // when aspect ratio is less than 1 , video will be played in portrait mode and orientation will not be changed.
    var aspectRatio =
        widget.flickManager.flickVideoManager!.videoPlayerValue!.aspectRatio;
    if (_isFullscreen && aspectRatio >= 1) {
      SystemChrome.setPreferredOrientations(
          widget.preferredDeviceOrientationFullscreen);
    } else {
      SystemChrome.setPreferredOrientations(widget.preferredDeviceOrientation);
    }
  }

  _setSystemUIOverlays() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: widget.systemUIOverlayFullscreen);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: widget.systemUIOverlay);
    }
  }

  void _webFullscreenListener(Event event) {
    final isFullscreen = (window.screenTop == 0 && window.screenY == 0);
    if (isFullscreen && !flickManager.flickControlManager!.isFullscreen) {
      flickManager.flickControlManager!.enterFullscreen();
    } else if (!isFullscreen &&
        flickManager.flickControlManager!.isFullscreen) {
      flickManager.flickControlManager!.exitFullscreen();
    }
  }

  void _webKeyListener(KeyboardEvent event) {
    widget.webKeyDownHandler(event, flickManager);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityDetectorKey,
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.5) {
          flickManager.flickControlManager!.pause();
        }
      },
      child: SizedBox(
        width: _videoWidth,
        height: _videoHeight,
        child: FlickManagerBuilder(
          flickManager: flickManager,
          child: widget.flickVideoWithControls,
        ),
      ),
    );
  }
}
