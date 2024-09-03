import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_feed.dart';
import 'package:wherostr_social/models/app_locale.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/screens/app_relay_settings.dart';
import 'package:wherostr_social/screens/create_account.dart';
import 'package:wherostr_social/screens/home.dart';
import 'package:wherostr_social/screens/login.dart';
import 'package:wherostr_social/screens/splash.dart';
import 'package:wherostr_social/screens/test.dart';
import 'package:wherostr_social/screens/welcome.dart';

void main() async {
  await GetStorage.init('app');
  await AppRelays.init();
  runApp(const MainApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/app-relay-settings',
      builder: (context, state) => const AppRelaySettings(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/test',
      builder: (context, state) => const TestScreen(),
    ),
  ],
);

class MainApp extends StatelessWidget {
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppFeedProvider()),
        ChangeNotifierProvider(create: (_) => AppLocaleProvider()),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStatesProvider()),
      ],
      child: Consumer2<AppLocaleProvider, AppThemeProvider>(
        builder: (context, appLocale, appTheme, child) => GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MaterialApp.router(
            scaffoldMessengerKey: scaffoldMessengerKey,
            routerConfig: _router,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: appLocale.locale,
            theme: lightThemeData,
            darkTheme: darkThemeData,
            themeMode: appTheme.themeMode,
          ),
        ),
      ),
    );
  }
}
