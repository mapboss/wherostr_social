import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AppSettingsProvider with ChangeNotifier {
  AppSettingsProvider() {
    _init();
  }

  bool _collapseLongPost = true;
  double _contentFontSizeDelta = 0;
  bool _initializedMessages = false;

  bool get collapseLongPost => _collapseLongPost;
  double get contentFontSizeDelta => _contentFontSizeDelta;
  bool get initializedMessages => _initializedMessages;

  Future<void> _init() async {
    final storage = GetStorage('app');
    _collapseLongPost = storage.read('app_settings_collapse_long_post') ?? true;
    _contentFontSizeDelta =
        storage.read('app_settings_content_font_size_delta') ?? 0;
  }

  Future<void> setCollapseLongPost(bool collapseLongPost) async {
    final storage = GetStorage('app');
    await storage.write('app_settings_collapse_long_post', collapseLongPost);
    _collapseLongPost = collapseLongPost;
    notifyListeners();
  }

  Future<void> setContentFontSizeDelta(double contentFontSizeDelta) async {
    var storage = GetStorage('app');
    await storage.write(
        'app_settings_content_font_size_delta', contentFontSizeDelta);
    _contentFontSizeDelta = contentFontSizeDelta;
    notifyListeners();
  }

  Future<void> setInitializedMessages(bool initializedMessages) async {
    var storage = GetStorage('app');
    await storage.write(
        'app_settings_initialized_messages', initializedMessages);
    _initializedMessages = initializedMessages;
    notifyListeners();
  }
}
