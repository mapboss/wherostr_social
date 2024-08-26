import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/app_utils.dart';
import 'package:wherostr_social/widgets/profile.dart';
import 'package:wherostr_social/widgets/profile_avatar.dart';
import 'package:wherostr_social/widgets/profile_display_name.dart';

class MutedAccountSettings extends StatefulWidget {
  const MutedAccountSettings({super.key});

  @override
  State<MutedAccountSettings> createState() => _MutedAccountSettingsState();
}

class _MutedAccountSettingsState extends State<MutedAccountSettings> {
  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStatesProvider>();
    final muteList = appState.me.muteList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muted accounts'),
      ),
      body: muteList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No items'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: muteList.length,
              itemBuilder: (context, index) => Padding(
                key: Key(muteList[index]),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ProfileListTile(
                      pubkey: muteList[index],
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
    );
  }
}

class ProfileListTile extends StatefulWidget {
  final String pubkey;

  const ProfileListTile({
    super.key,
    required this.pubkey,
  });

  @override
  State<ProfileListTile> createState() => _ProfileListTileState();
}

class _ProfileListTileState extends State<ProfileListTile> {
  NostrUser? _user;
  bool _isMuted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final me = context.read<AppStatesProvider>().me;
    NostrUser user = await NostrService.fetchUser(widget.pubkey);
    if (mounted) {
      setState(() {
        _user = user;
        _isMuted = me.muteList.contains(widget.pubkey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appState = context.watch<AppStatesProvider>();
    return _user == null
        ? Shimmer.fromColors(
            baseColor: themeExtension.shimmerBaseColor!,
            highlightColor: themeExtension.shimmerHighlightColor!,
            child: ListTile(
              contentPadding: const EdgeInsets.all(0),
              minTileHeight: 64.0,
              horizontalTitleGap: 8,
              leading: const CircleAvatar(),
              title: Container(
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                color: Colors.white,
              ),
            ),
          )
        : ListTile(
            contentPadding: const EdgeInsets.all(0),
            minTileHeight: 64,
            horizontalTitleGap: 8,
            leading: InkWell(
              onTap: () => appState.navigatorPush(
                widget: Profile(
                  user: _user!,
                ),
              ),
              child: ProfileAvatar(url: _user!.picture),
            ),
            title: ProfileDisplayName(
              user: _user,
              textStyle: themeData.textTheme.titleMedium,
              withBadge: true,
              enableShowProfileAction: true,
            ),
            subtitle: _user!.nip05 == null
                ? null
                : Text(
                    _user!.nip05!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Transform.translate(
              offset: const Offset(4, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_user != null)
                    _isMuted
                        ? OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    try {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await appState.unmute(_user!.pubkey);
                                      setState(() {
                                        _isMuted = false;
                                      });
                                    } catch (error) {
                                      AppUtils.handleError();
                                    } finally {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                            child: const Text('Unmute'),
                          )
                        : OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    try {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      await appState.mute(_user!.pubkey);
                                      setState(() {
                                        _isMuted = true;
                                      });
                                    } catch (error) {
                                      AppUtils.handleError();
                                    } finally {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                            child: Text(
                              'Mute',
                              style:
                                  TextStyle(color: themeData.colorScheme.error),
                            ),
                          ),
                ],
              ),
            ),
          );
  }
}
