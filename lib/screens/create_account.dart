import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/gradient_decorated_box.dart';
import 'package:wherostr_social/widgets/profile_editing.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create account'),
        ),
        body: GradientDecoratedBox(
          child: ProfileEditing(
            submitButtonLabel: 'Create',
            onBeforeSubmit: () {
              setState(() {
                _isLoading = true;
              });
            },
            onSubmit: ({
              picture,
              banner,
              name,
              displayName,
              about,
              website,
              lud16,
              lud06,
              nip05,
            }) async {
              if (mounted) {
                AppUtils.showSnackBar(
                  text: 'Creating...',
                  withProgressBar: true,
                  autoHide: false,
                );
                final appState = context.read<AppStatesProvider>();
                final keypairs = NostrKeyPairs.generate();
                try {
                  await appState.setMe(keypairs);
                  await NostrService.instance.relaysService.init(
                      connectionTimeout: const Duration(seconds: 5),
                      relaysUrl: AppRelays.defaults
                          .leftCombine(AppRelays.relays)
                          .toListString());
                  await appState.updateProfile(
                    picture: picture,
                    banner: banner,
                    name: name,
                    displayName: displayName,
                    about: about,
                    website: website,
                    lud16: lud16,
                    lud06: lud06,
                    nip05: nip05,
                  );
                  await appState.me.initializeAll();
                  appState.me.initRelays(AppRelays.relays);
                  AppUtils.showSnackBar(
                    text: 'Created successfully.',
                    status: AppStatus.success,
                  );
                  NostrService.instance.disableLogs();
                  context.go('/home');
                } catch (error) {
                  AppUtils.hideSnackBar();
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
