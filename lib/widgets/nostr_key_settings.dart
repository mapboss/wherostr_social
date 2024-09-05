import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';

class NostrKeySettings extends StatefulWidget {
  const NostrKeySettings({super.key});

  @override
  State<NostrKeySettings> createState() => _NostrKeySettingsState();
}

class _NostrKeySettingsState extends State<NostrKeySettings> {
  final TextEditingController _publicKeyTextController =
      TextEditingController();
  final TextEditingController _privateKeyTextController =
      TextEditingController();
  bool _obscurePivateKey = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final keypairs = (await AppSecret.read())!;
    _publicKeyTextController.text = NostrService.instance.keysService
        .encodePublicKeyToNpub(keypairs.public);
    _privateKeyTextController.text = NostrService.instance.keysService
        .encodePrivateKeyToNsec(keypairs.private);
  }

  @override
  void dispose() {
    _publicKeyTextController.dispose();
    _privateKeyTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr keys'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Public key (npub)',
                  style: themeData.textTheme.titleMedium!
                      .copyWith(color: themeExtension.textDimColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _publicKeyTextController,
                  decoration: InputDecoration(
                    filled: true,
                    isDense: true,
                    suffix: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: _publicKeyTextController.text,
                          ),
                        );
                        AppUtils.showSnackBar(
                          text: 'Public key copied',
                          status: AppStatus.success,
                        );
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text.rich(
                  TextSpan(
                    text:
                        'A Nostr public key, essentially your unique identifier on the Nostr network and similar to a username on a traditional social media platform, is visible to everyone.',
                    style: TextStyle(color: themeExtension.textDimColor),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Private key (nsec)',
                  style: themeData.textTheme.titleMedium!
                      .copyWith(color: themeData.colorScheme.error),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _privateKeyTextController,
                  decoration: InputDecoration(
                    filled: true,
                    isDense: true,
                    prefix: IconButton(
                      icon: Icon(_obscurePivateKey
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() {
                        _obscurePivateKey = !_obscurePivateKey;
                      }),
                    ),
                    suffix: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: _privateKeyTextController.text,
                          ),
                        );
                        AppUtils.showSnackBar(
                          text: 'Private key copied',
                          status: AppStatus.success,
                        );
                      },
                    ),
                  ),
                  obscureText: _obscurePivateKey,
                  readOnly: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: themeExtension.textDimColor),
                    children: [
                      const TextSpan(
                        text:
                            'A Nostr private key is the cryptographic counterpart to your public key. It\'s essentially the password to your Nostr account.\n',
                      ),
                      TextSpan(
                        text: 'Never share your private key: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'If someone else obtains your private key, they can impersonate you and control your account.\n',
                      ),
                      TextSpan(
                        text: 'Backup your private key: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'It\'s crucial to have a secure backup of your private key in case you lose access to your devices.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning,
                      color: themeData.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete account',
                      style: themeData.textTheme.titleMedium!
                          .copyWith(color: themeData.colorScheme.error),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  text:
                      'Once you delete your account, you will not be able to sign in or recover your data. This action is irreversible.',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: themeData.colorScheme.error),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                color: themeData.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              const Text('Confirm Deletion'),
                            ],
                          ),
                          content: const Text(
                              'Are you sure you want to delete your account? This action is permanent and cannot be undone. You will not be able to sign in or recover any data after deletion.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
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
                                  final me =
                                      context.read<AppStatesProvider>().me;
                                  await me.updateProfile(
                                    name: 'Deleted Account',
                                  );
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
                                'Delete account',
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
                  child: Text(
                    'Delete account',
                    style: TextStyle(
                      color: themeData.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
