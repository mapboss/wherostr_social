import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AppLocaleProvider with ChangeNotifier {
  AppLocaleProvider() {
    _init();
  }
  var _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> _init() async {
    var storage = GetStorage('app');
    if (storage.hasData('app_locale')) {
      _locale = Locale(storage.read('app_locale'));
    } else {
      _locale = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    var storage = GetStorage('app');
    await storage.write('app_locale', locale.languageCode);
    _locale = locale;
    notifyListeners();
  }
}
