import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/widgets/main_feed.dart';

class AppStatesProvider with ChangeNotifier {
  static GlobalKey<ScaffoldState> homeScaffoldKey = GlobalKey();
  static GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey();
  static GlobalKey<MainFeedState> mainFeedKey = GlobalKey();

  NostrUser? _me;
  NostrUser get me => _me ?? NostrUser(pubkey: '');

  void navigatorPush({
    required Widget widget,
    bool rootNavigator = false,
  }) {
    Navigator.of(homeNavigatorKey.currentContext!, rootNavigator: rootNavigator)
        .push(MaterialPageRoute(builder: (context) => widget));
  }

  void navigatorPop({
    bool tryRootNavigatorFirst = true,
  }) {
    final context = homeNavigatorKey.currentContext!;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final navigator = Navigator.of(context);
    if (tryRootNavigatorFirst && rootNavigator.canPop()) {
      rootNavigator.pop();
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<bool> isLoggedIn() async {
    NostrKeyPairs? keyPairs = await AppSecret.read();
    if (keyPairs == null) return false;
    return true;
  }

  Future<bool> login(String nsec) async {
    if (!verifyNsec(nsec)) return false;
    final privateKey = nsecToPrivateKey(nsec);
    if (privateKey == null) return false;
    await AppSecret.write(privateKey);
    return true;
  }

  Future<void> logout() async {
    await Future.wait([AppSecret.delete(), NostrService.instance.dispose()]);
    _me = null;
    NostrService.instance = Nostr();
  }

  bool verifyNsec(String nsec) {
    if (!nsec.startsWith('nsec1')) return false;
    String nsecHex = '';
    try {
      nsecHex = Nostr.instance.keysService.decodeNsecKeyToPrivateKey(nsec);
    } catch (err) {
      print(err);
    }
    if (!NostrKeyPairs.isValidPrivateKey(nsecHex)) return false;
    return true;
  }

  String? nsecToPrivateKey(String nsec) {
    if (!nsec.startsWith('nsec1')) return null;
    String nsecHex = '';
    try {
      nsecHex = Nostr.instance.keysService.decodeNsecKeyToPrivateKey(nsec);
    } catch (err) {
      print(err);
    }
    if (!NostrKeyPairs.isValidPrivateKey(nsecHex)) return null;
    return nsecHex;
  }

  Future<NostrUser?> setMe(NostrKeyPairs keypairs) async {
    await AppSecret.write(keypairs.private);
    _me = NostrUser(pubkey: keypairs.public);
    return _me;
  }

  Future<bool?> init() async {
    NostrKeyPairs? keypairs = await AppSecret.read();
    if (keypairs == null) return null;
    print('init.pubkey: ${keypairs.public}');
    await setMe(keypairs);
    final relays = await NostrService.initWithNpubOrPubkey(keypairs.public);
    await me.fetchProfile();
    if (me.displayName == 'Deleted Account') {
      return false;
    } else {
      me.initRelays(relays);
      await Future.wait([
        me.fetchFollowing(),
        me.fetchMuteList(),
        me.fetchFollowSets(),
        me.fetchInterestSets()
      ]);
      notifyListeners();
      return true;
    }
  }

  Future<void> updateProfile({
    String? picture,
    String? banner,
    String? name,
    String? displayName,
    String? about,
    String? website,
    String? lud06,
    String? lud16,
    String? nip05,
    DataRelayList? relays,
  }) async {
    await me.updateProfile(
      picture: picture,
      banner: banner,
      name: name,
      displayName: displayName,
      about: about,
      website: website,
      lud06: lud06,
      lud16: lud16,
      nip05: nip05,
      relays: relays,
    );
    notifyListeners();
  }

  Future<void> mute(String user) async {
    await me.mute(user);
    notifyListeners();
  }

  Future<void> unmute(String user) async {
    await me.unmute(user);
    notifyListeners();
  }

  Future<void> setRelays(DataRelayList relays) async {
    await me.setRelays(relays);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await me.unfollowAll();
    await me.updateProfile(
      name: 'Deleted Account',
    );
    notifyListeners();
  }
}
