import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AppLocaleProvider with ChangeNotifier {
  AppLocaleProvider() {
    _init();
  }

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> _init() async {
    final storage = GetStorage('app');
    _locale = Locale(storage.read('app_locale') ?? 'en');
  }

  Future<void> setLocale(Locale locale) async {
    final storage = GetStorage('app');
    await storage.write('app_locale', locale.languageCode);
    _locale = locale;
    notifyListeners();
  }
}
