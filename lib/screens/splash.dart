import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/themed_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Completer<bool?> _isInitialized = Completer<bool?>();
  bool _isLoggedIn = false;
  double _scale = 0.1;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _initialize();
  }

  void _startAnimation() {
    Timer.run(() {
      setState(() {
        _scale = 0.35;
        _opacity = 1;
      });
    });
  }

  void _initialize() async {
    var appState = context.read<AppStatesProvider>();
    bool isLoggedIn = await appState.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
    if (isLoggedIn) {
      final isValidAccount = await appState.init();
      if (isValidAccount == false) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Account Deleted'),
              content: const Text(
                  'This account has been permanently deleted and cannot be accessed. Please create a new account to continue using Wherostr.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    AppUtils.showLoading();
                    await context.read<AppStatesProvider>().logout();
                    AppUtils.hideLoading();
                    context.go('/welcome');
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
      } else {
        _isInitialized.complete(true);
      }
    } else {
      _isInitialized.complete(true);
    }
  }

  void _onSplashed() async {
    await _isInitialized.future;
    if (_isLoggedIn) {
      return scheduleMicrotask(() => context.go('/home'));
      // return scheduleMicrotask(() => context.go('/test'));
    }
    return scheduleMicrotask(() => context.go('/welcome'));
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      backgroundColor: themeData.colorScheme.surfaceDim,
      body: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 2000),
          onEnd: _onSplashed,
          opacity: _opacity,
          child: Center(
            child: LimitedBox(
              maxWidth: MediaQuery.sizeOf(context).width * 0.5,
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              child: const ThemedLogo(
                textEnabled: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
