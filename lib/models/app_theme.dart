import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

@immutable
class MyThemeExtension extends ThemeExtension<MyThemeExtension> {
  const MyThemeExtension({
    required this.textDimColor,
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
  });

  final Color? textDimColor;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;
  final Color successColor = const Color.fromRGBO(56, 142, 60, 1);
  final Color infoColor = const Color.fromRGBO(2, 136, 209, 1);
  final Color warningColor = const Color.fromRGBO(245, 124, 0, 1);
  final Color errorColor = const Color.fromRGBO(207, 102, 121, 1);

  @override
  MyThemeExtension copyWith(
      {Color? textDimColor,
      Color? shimmerBaseColor,
      Color? shimmerHighlightColor}) {
    return MyThemeExtension(
      textDimColor: textDimColor ?? this.textDimColor,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor:
          shimmerHighlightColor ?? this.shimmerHighlightColor,
    );
  }

  @override
  MyThemeExtension lerp(MyThemeExtension? other, double t) {
    if (other is! MyThemeExtension) {
      return this;
    }
    return MyThemeExtension(
      textDimColor: Color.lerp(textDimColor, other.textDimColor, t),
      shimmerBaseColor: Color.lerp(shimmerBaseColor, other.shimmerBaseColor, t),
      shimmerHighlightColor:
          Color.lerp(shimmerHighlightColor, other.shimmerHighlightColor, t),
    );
  }
}

final lightThemeData = ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color.fromRGBO(20, 121, 112, 1),
    secondary: Color.fromRGBO(250, 178, 16, 1),
    surfaceDim: Color.fromRGBO(245, 246, 250, 1),
    outline: Color.fromRGBO(217, 217, 217, 1),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 1,
    scrolledUnderElevation: 1,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black,
  ),
  scaffoldBackgroundColor: const Color.fromRGBO(245, 246, 250, 1),
  menuTheme: const MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(
        Color.fromRGBO(245, 246, 250, 1),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    dense: true,
    subtitleTextStyle: TextStyle(
      color: Color.fromRGBO(121, 121, 121, 1),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color.fromRGBO(245, 246, 250, 1),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(
      color: Color.fromRGBO(121, 121, 121, 1),
    ),
  ),
  filledButtonTheme: const FilledButtonThemeData(
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
    ),
  ),
  outlinedButtonTheme: const OutlinedButtonThemeData(
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
    ),
  ),
  extensions: const <ThemeExtension<dynamic>>[
    MyThemeExtension(
      textDimColor: Color.fromRGBO(121, 121, 121, 1),
      shimmerBaseColor: Color.fromRGBO(217, 217, 217, 0.2),
      shimmerHighlightColor: Color.fromRGBO(20, 121, 112, 0.2),
    ),
  ],
);
final darkThemeData = ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color.fromRGBO(20, 121, 112, 1),
    secondary: Color.fromRGBO(250, 178, 16, 1),
    surfaceDim: Color.fromRGBO(24, 24, 24, 1),
    outline: Color.fromRGBO(217, 217, 217, 1),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 1,
    scrolledUnderElevation: 1,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black,
  ),
  scaffoldBackgroundColor: const Color.fromRGBO(24, 24, 24, 1),
  menuTheme: const MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(
        Color.fromRGBO(24, 24, 24, 1),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    dense: true,
    subtitleTextStyle: TextStyle(
      color: Color.fromRGBO(121, 121, 121, 1),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color.fromRGBO(24, 24, 24, 1),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(
      color: Color.fromRGBO(121, 121, 121, 1),
    ),
  ),
  filledButtonTheme: const FilledButtonThemeData(
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
    ),
  ),
  outlinedButtonTheme: const OutlinedButtonThemeData(
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
    ),
  ),
  extensions: const <ThemeExtension<dynamic>>[
    MyThemeExtension(
      textDimColor: Color.fromRGBO(121, 121, 121, 1),
      shimmerBaseColor: Color.fromRGBO(217, 217, 217, 0.2),
      shimmerHighlightColor: Color.fromRGBO(20, 121, 112, 0.2),
    ),
  ],
);

class AppThemeProvider with ChangeNotifier {
  AppThemeProvider() {
    _init();
  }
  var _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> _init() async {
    var storage = GetStorage('app');
    if (storage.hasData('app_theme_mode')) {
      switch (storage.read('app_theme_mode')) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        default:
          _themeMode = ThemeMode.dark;
          break;
      }
    } else {
      _themeMode = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    var storage = GetStorage('app');
    String themeModeValue;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeValue = 'light';
        break;
      default:
        themeModeValue = 'dark';
        break;
    }
    await storage.write('app_theme_mode', themeModeValue);
    _themeMode = themeMode;
    notifyListeners();
  }
}
