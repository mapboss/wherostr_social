import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:wherostr_social/main.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';

enum AppStatus { success, info, warning, error }

class AppUtils {
  static Icon statusIcon({
    required BuildContext context,
    required AppStatus status,
    double? size,
  }) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    switch (status) {
      case AppStatus.success:
        return Icon(
          Icons.check_circle,
          color: themeExtension.successColor,
          size: size,
        );
      case AppStatus.info:
        return Icon(
          Icons.info,
          color: themeExtension.infoColor,
          size: size,
        );
      case AppStatus.warning:
        return Icon(
          Icons.warning_rounded,
          color: themeExtension.warningColor,
          size: size,
        );
      case AppStatus.error:
        return Icon(
          Icons.cancel,
          color: themeExtension.errorColor,
          size: size,
        );
    }
  }

  static void showLoading({BuildContext? context}) {
    context = context ?? AppStatesProvider.homeScaffoldKey.currentContext;
    if (context?.mounted == true) {
      showDialog(
        context: context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const SimpleDialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            children: [
              Center(
                child: CircularProgressIndicator(),
              )
            ],
          );
        },
      );
    }
  }

  static void hideLoading({BuildContext? context}) {
    context = context ?? AppStatesProvider.homeScaffoldKey.currentContext;
    if (context?.mounted == true) {
      Navigator.of(context!).pop();
    }
  }

  static void showSnackBar({
    required String text,
    bool withProgressBar = false,
    bool autoHide = true,
    AppStatus? status,
  }) {
    MainApp.scaffoldMessengerKey.currentState?.clearSnackBars();
    MainApp.scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      padding: const EdgeInsets.all(0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (withProgressBar) ...[const LinearProgressIndicator()],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (status != null &&
                    AppStatesProvider.homeScaffoldKey.currentContext !=
                        null) ...[
                  statusIcon(
                      context:
                          AppStatesProvider.homeScaffoldKey.currentContext!,
                      status: status),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
          ),
        ],
      ),
      duration: autoHide ? const Duration(seconds: 4) : const Duration(days: 1),
      showCloseIcon: autoHide,
    ));
  }

  static void hideSnackBar() {
    MainApp.scaffoldMessengerKey.currentState?.clearSnackBars();
  }

  static AppImageCacheManager appImageCacheManager = AppImageCacheManager();
  static ImageProvider getCachedImageProvider(String url, int? maxSize) =>
      url.endsWith('.svg')
          ? (Svg(url, source: SvgSource.network) as ImageProvider)
          : CachedNetworkImageProvider(
              url,
              cacheManager: appImageCacheManager,
              maxHeight: maxSize,
              maxWidth: maxSize,
              errorListener: (err) => print('getCachedImageProvider: $err'),
            );
  static ImageProvider getImageProvider(String url) => url.endsWith('.svg')
      ? (Svg(url, source: SvgSource.network) as ImageProvider)
      : Image.network(url).image;

  static void handleError() {
    AppUtils.showSnackBar(
      text: 'An error occurred.',
      status: AppStatus.error,
    );
  }

  static void scrollToTop(
    BuildContext? context,
  ) {
    if (context == null) {
      return;
    }
    final scrollController = PrimaryScrollController.of(context);
    if (scrollController.hasClients) {
      scrollController.animateTo(scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic);
    }
  }
}

class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'appImageCacheKey';
  static final AppImageCacheManager _instance = AppImageCacheManager._();

  factory AppImageCacheManager() {
    return _instance;
  }

  AppImageCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
        ));
}

const wherostrBackgroundDecoration = BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/app/logo-background-repeat.png'),
    repeat: ImageRepeat.repeat,
    opacity: 0.054,
  ),
);
