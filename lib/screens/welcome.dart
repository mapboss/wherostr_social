import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/constant.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/themed_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLargeDisplay =
        MediaQuery.sizeOf(context).width >= Constants.largeDisplayWidth;
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const ThemedLogo(height: 120),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Wherostr',
                    style: themeData.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A decentralized geo-social app built on the Nostr protocol',
                    textAlign: TextAlign.center,
                    style: themeData.textTheme.bodyLarge?.apply(
                      color: themeExtension.textDimColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'What is Nostr?',
                    style: themeData.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nostr is a decentralized protocol for social networking, allowing users to interact without relying on a central authority.',
                    textAlign: TextAlign.center,
                    style: themeData.textTheme.bodyLarge?.apply(
                      color: themeExtension.textDimColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Why we need Nostr?',
                    style: themeData.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nostr provides a secure and private way to connect with others, ensuring data ownership and freedom from censorship.',
                    textAlign: TextAlign.center,
                    style: themeData.textTheme.bodyLarge?.apply(
                      color: themeExtension.textDimColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        Material(
          borderRadius: isLargeDisplay
              ? const BorderRadiusDirectional.vertical(
                  top: Radius.circular(12),
                )
              : null,
          elevation: 1,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text.rich(
                          TextSpan(
                            style:
                                TextStyle(color: themeExtension.textDimColor),
                            children: [
                              const TextSpan(
                                text: 'By proceeding, you agree to our\n',
                              ),
                              TextSpan(
                                text: 'EULA',
                                style: TextStyle(
                                  color: themeData.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(Uri.parse(
                                      'https://wherostr.social/eula')),
                              ),
                              const TextSpan(
                                text: ' and ',
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: themeData.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => launchUrl(Uri.parse(
                                      'https://wherostr.social/privacy-policy')),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            AppStatesProvider.homeScaffoldKey = GlobalKey();
                            AppStatesProvider.homeNavigatorKey = GlobalKey();
                            AppStatesProvider.mainFeedKey = GlobalKey();
                            context.go('/login');
                          },
                          child: const Text("Let's get started!"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: wherostrBackgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: isLargeDisplay
              ? Row(
                  children: [
                    const Expanded(
                      flex: 1,
                      child: SizedBox.shrink(),
                    ),
                    SizedBox(
                      width: Constants.largeDisplayContentWidth,
                      child: child,
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox.shrink(),
                    ),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
