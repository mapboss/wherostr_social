import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/appearance_settings.dart';
import 'package:wherostr_social/widgets/following_hashtag_settings.dart';
import 'package:wherostr_social/widgets/muted_account_settings.dart';
import 'package:wherostr_social/widgets/nostr_key_settings.dart';
import 'package:wherostr_social/widgets/relay_settings.dart';

class SettingsContainer extends StatefulWidget {
  const SettingsContainer({super.key});

  @override
  State<SettingsContainer> createState() => _SettingsContainerState();
}

class _SettingsContainerState extends State<SettingsContainer> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Material(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Your account',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Nostr keys'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.read<AppStatesProvider>().navigatorPush(
                        widget: const NostrKeySettings(),
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.hub),
                  title: const Text('Relays'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.read<AppStatesProvider>().navigatorPush(
                        rootNavigator: true,
                        widget: const RelaySettings(),
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_off),
                  title: const Text('Muted accounts'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.read<AppStatesProvider>().navigatorPush(
                        widget: const MutedAccountSettings(),
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: const Text('Following hashtags'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.read<AppStatesProvider>().navigatorPush(
                        widget: const FollowingHashtagSettings(),
                      ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'App settings',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.style),
                  title: const Text('Appearance'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.read<AppStatesProvider>().navigatorPush(
                        widget: const AppearanceSettings(),
                      ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Information',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About Nostr'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => launchUrl(Uri.parse('https://nostr.org/')),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Sign in',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  iconColor: themeData.colorScheme.error,
                  textColor: themeData.colorScheme.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                color: themeExtension.warningColor,
                              ),
                              const SizedBox(width: 8),
                              const Text('Before logging out'),
                            ],
                          ),
                          content: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Please ensure you have saved your ',
                                ),
                                TextSpan(
                                  text: 'Nostr private key',
                                  style: TextStyle(
                                    color: themeExtension.warningColor,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' securely. Without it, you will not be able to sign in again.',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: themeData.colorScheme.inverseSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  AppUtils.showLoading();
                                  await context
                                      .read<AppStatesProvider>()
                                      .logout();
                                  AppUtils.hideLoading();
                                  context.go('/welcome');
                                } catch (error) {
                                  AppUtils.hideLoading();
                                  AppUtils.handleError();
                                }
                              },
                              child: Text(
                                'Sign out',
                                style: TextStyle(
                                  color: themeData.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'App version: ${_packageInfo?.version}',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
