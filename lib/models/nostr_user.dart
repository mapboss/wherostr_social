import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:uuid/uuid.dart';
import 'package:wherostr_social/extension/nostr_instance.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

class NostrUser {
  NostrUser(
      {required this.pubkey,
      this.name,
      displayName,
      this.picture,
      this.nip05,
      this.website,
      this.image,
      this.banner,
      this.about,
      this.lud16,
      this.lud06,
      this.createdAt})
      : _displayName = displayName;

  final String pubkey;
  String? name;
  String? _displayName;
  String? nip05;
  String? website;
  String? image;
  String? picture;
  String? banner;
  String? about;
  String? lud16;
  String? lud06;
  DateTime? createdAt;

  Completer<bool?>? _isNostrAddressVerified;

  List<String>? _followers;
  List<String> get followers => _followers ?? [];
  bool get isFollowerFetched => _followers != null;

  List<String>? _following;
  List<String> get following => _following ?? [];

  List<String>? _muteList;
  List<String> get muteList => _muteList ?? [];

  List<String>? _interestSets;
  List<String> get interestSets => _interestSets ?? [];

  List<FollowSet>? _followSets;
  List<FollowSet> get followSets => _followSets ?? [];

  List<String>? _pinList;
  List<String> get pinList => _pinList ?? [];

  List<String>? _bookmarkList;
  List<String> get bookmarkList => _bookmarkList ?? [];

  List<List<String>>? _emojiList;
  List<List<String>> get emojiList => _emojiList ?? [];

  DataRelayList? _relayList;
  DataRelayList get relayList => _relayList ?? DataRelayList();

  String get npub => Nostr.instance.keysService.encodePublicKeyToNpub(pubkey);

  set displayName(String? value) {
    _displayName = value;
  }

  String? get rawDisplayName => _displayName;

  String get displayName {
    if (_displayName?.isNotEmpty ?? false) {
      return _displayName!;
    }
    if (name?.isNotEmpty ?? false) {
      return name!;
    }
    return npub.substring(0, 12);
  }

  Future<void> initializeAll() async {
    _followers = [];
    _pinList = [];
    _bookmarkList = [];
    await Future.wait([
      unfollowAll(),
      unmuteAll(),
      initInterestSets(),
      initFollowSets(),
      initEmojiList(),
      setRelays(DataRelayList())
    ]);
  }

  Future<void> initInterestSets() async {
    _interestSets = [];
    await setInterestSets(interestSets);
  }

  Future<void> initFollowSets() async {
    _followSets = [];
    final event = DataEvent(kind: 30000, tags: [
      ['d', const Uuid().v4()],
      const ['title', 'Wherostr Map'],
    ]);
    await event.publish(relays: _relayList);
  }

  Future<void> initEmojiList() async {
    _emojiList = [];
    final event = DataEvent(kind: 10030, tags: const [
      [
        'a',
        '30030:fc43cb888ec0fbb74a75c19e80738a88706eab2e9959616b94624a718a60fa73:Wherostr'
      ]
    ]);
    await event.publish(relays: _relayList);
  }

  factory NostrUser.fromJson(Map<String, dynamic> data) {
    String pubkey = data['pubkey'];
    String? name = SafeParser.parseString(data['name']);
    String? displayName = SafeParser.parseString(data['display_name']);

    String? nip05 = SafeParser.parseString(data['nip05']);
    String? website = SafeParser.parseString(data['website']);
    String? image = SafeParser.parseString(data['image']);
    String? picture = SafeParser.parseString(data['picture']) ?? image;

    String? banner = SafeParser.parseString(data['banner']);
    String? about = SafeParser.parseString(data['about']);
    String? lud16 = SafeParser.parseString(data['lud16']);
    String? lud06 = SafeParser.parseString(data['lud06']);
    DateTime? createdAt = SafeParser.parseDateTime(data['createdAt']);

    return NostrUser(
      pubkey: pubkey,
      name: name,
      displayName: displayName,
      nip05: nip05,
      website: website,
      image: image,
      picture: picture,
      banner: banner,
      about: about,
      lud16: lud16,
      lud06: lud06,
      createdAt: createdAt,
    );
  }

  factory NostrUser.fromEvent(NostrEvent event) {
    final userJson = jsonDecode(event.content!);
    userJson['pubkey'] = event.pubkey;
    userJson['createdAt'] = event.createdAt;
    return NostrUser.fromJson(userJson);
  }

  Future<NostrUser> fetchProfile([bool force = false]) async {
    final profile = await NostrService.fetchUser(
      pubkey,
      relays: _relayList,
      force: force,
    );
    name = profile.name;
    displayName = profile._displayName;
    nip05 = profile.nip05;
    website = profile.website;
    image = profile.image;
    picture = profile.picture;
    banner = profile.banner;
    about = profile.about;
    lud16 = profile.lud16;
    lud06 = profile.lud06;
    return this;
  }

  Future<bool?> verifyNostrAddress() async {
    if (_isNostrAddressVerified == null) {
      _isNostrAddressVerified = Completer<bool?>();
    } else {
      return _isNostrAddressVerified!.future;
    }

    if (nip05 == null || nip05!.isEmpty) {
      _isNostrAddressVerified!.complete(null);
      return _isNostrAddressVerified!.future;
    }

    NostrService.instance.utilsService
        .verifyNip05(
          internetIdentifier: nip05!,
          pubKey: pubkey,
        )
        .then((isValid) => _isNostrAddressVerified!.complete(isValid))
        .catchError((err) => _isNostrAddressVerified!.complete(false));

    return _isNostrAddressVerified!.future;
  }

  Future<List<String>> fetchFollowing([bool force = false]) async {
    print('fetchFollowing');
    if (!force && _following != null) {
      print('fetchFollowing.cache: ${_following?.length}');
      return following;
    }
    NostrFilter filter =
        NostrFilter(kinds: const [3], authors: [pubkey], limit: 1);
    final events = await NostrService.instance.fetchEvents(
      [filter],
      timeout: const Duration(seconds: 10),
      relays: _relayList,
    );
    print('fetchFollowing.events: ${events.length}');
    if (events.isEmpty || events.firstOrNull?.tags == null) {
      return [];
    }
    final pubkeyList = events.firstOrNull?.tags!
        .where((item) => item.firstOrNull == 'p')
        .map((item) => item[1]);
    _following = pubkeyList?.toSet().toList();
    print('fetchFollowing: ${_following?.length}');
    // if (pubkeyList != null) {
    // await NostrService.fetchUsers(pubkeyList.toSet().toList());
    // }
    return following;
  }

  Future<List<String>> fetchFollower([bool force = false]) async {
    print('fetchFollower');
    if (!force && _followers != null) {
      print('fetchFollower.cache: ${followers.length}');
      return followers;
    }
    // NostrFilter request = NostrFilter(kinds: const [3], p: [pubkey]);
    // final events = await NostrService.fetchEvents(
    //   [request],
    //   eoseRatio: 1,
    //   timeout: const Duration(seconds: 3),
    //   relays: _relayList,
    // );
    // if (events.isEmpty) {
    //   return [];
    // }
    // final pubkeyList = events.map((item) => item.pubkey);
    // _followers = pubkeyList.toSet().toList();
    // print('fetchFollower: ${_followers!.length}');

    var total = await _countFollower(pubkey);
    _followers = List.generate(total, (counter) => "Item $counter");
    print('fetchFollower: ${_followers!.length}');
    return followers;
  }

  Future<int> _countFollower(String pub) async {
    NostrFilter filter = NostrFilter(kinds: const [3], p: [pub], limit: 1);
    final total = await NostrService.countEvent(filter);
    print('countFollower.total: $total');
    return total;
  }

  Future<List<String>> fetchInterestSets([bool force = false]) async {
    print('fetchInterestSets');
    if (!force && _interestSets != null) {
      print('fetchInterestSets.cache: ${interestSets.length}');
      return interestSets;
    }
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10015], authors: [pubkey], limit: 1),
      NostrFilter(kinds: const [30015], authors: [pubkey]),
    ];
    final events = await NostrService.instance.fetchEvents(
      request,
      timeout: const Duration(seconds: 3),
      relays: _relayList,
    );
    print('fetchInterestSets.events: ${events.length}');
    List<String>? items;
    for (final event in events) {
      try {
        items ??= [];
        event.tags?.forEach(
          (element) {
            final tag = element.elementAt(1);
            if (element.first == 't' && items?.contains(tag) != true) {
              items?.add(tag);
            }
          },
        );
        if (event.kind == 10015) {
        } else if (event.kind == 30015) {}
      } catch (err) {
        print('fetchInterestSets: ${event.serialized()} ERROR: $err');
      }
    }
    _interestSets = items;
    return interestSets;
  }

  Future<List<FollowSet>> fetchFollowSets([bool force = false]) async {
    if (!force && _followSets != null) {
      print('fetchFollowSets.cache: ${followSets.length}');
      return followSets;
    }
    List<NostrFilter> request = [
      NostrFilter(kinds: const [30000], authors: [pubkey]),
    ];
    final events = await NostrService.instance.fetchEvents(
      request,
      timeout: const Duration(seconds: 3),
      relays: _relayList,
    );
    print('fetchFollowSets.events: ${events.length}');
    List<FollowSet>? items;
    for (final event in events) {
      try {
        items ??= [];
        String? id = event.getTagValue('d');
        if (id == null || id == 'mute') continue;
        final value = event.getTagValues('p');
        if (value == null || value.isEmpty) continue;
        String? name = event.getTagValue('title');
        if (name == null) continue;
        items.add(FollowSet(
            type: 'list', id: id, name: name, value: value.toSet().toList()));
      } catch (err) {
        print('fetchFollowSets: ${event.serialized()} ERROR: $err');
      }
    }
    _followSets = items;
    return followSets;
  }

  Future<List<String>> fetchMuteList([bool force = false]) async {
    if (!force && _muteList != null) {
      return muteList;
    }
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10000], authors: [pubkey], limit: 1),
    ];
    final events = await NostrService.instance.fetchEvents(
      request,
      timeout: const Duration(seconds: 3),
      relays: _relayList,
    );
    Set<String>? pubkeyList;
    for (final event in events) {
      pubkeyList ??= {};
      pubkeyList.addAll(event.tags!.where((e) => e.firstOrNull == 'p').map(
            (e) => e[1],
          ));
    }
    _muteList = pubkeyList?.toSet().toList();
    print('fetchMuteList: ${muteList.length}');
    return muteList;
  }

  Future<List<String>> fetchPinList([bool force = false]) async {
    if (!force && _pinList != null) {
      return pinList;
    }
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10001], authors: [pubkey], limit: 1),
    ];
    final events = await NostrService.instance.fetchEvents(
      request,
      relays: _relayList,
    );
    Set<String>? eventList;
    for (final event in events) {
      eventList ??= {};
      eventList.addAll(event.tags!.where((e) => e.firstOrNull == 'e').map(
            (e) => e[1],
          ));
    }
    _pinList = eventList?.toSet().toList();
    print('fetchPinList: ${pinList.length}');
    return pinList;
  }

  Future<List<String>> fetchBookmarkList([bool force = false]) async {
    if (!force && _bookmarkList != null) {
      return bookmarkList;
    }
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10003], authors: [pubkey], limit: 1),
      NostrFilter(kinds: const [30003], authors: [pubkey]),
    ];
    final events = await NostrService.instance.fetchEvents(
      request,
      relays: _relayList,
    );
    if (events.isEmpty) {
      return [];
    }
    Set<String>? eventList;
    for (final event in events) {
      eventList ??= {};
      if (event.kind == 10003) {
        eventList.addAll(event.tags!.where((e) => e.firstOrNull == 'e').map(
              (e) => e[1],
            ));
      } else if (event.kind == 30003) {}
    }
    _bookmarkList = eventList?.toSet().toList();
    print('fetchBookmarkList: ${bookmarkList.length}');
    return bookmarkList;
  }

  Future<List<List<String>>> fetchEmojiList([bool force = false]) async {
    if (!force && _emojiList != null) {
      return emojiList;
    }
    final emojiSetEvents = await NostrService.instance.fetchEvents(
      [
        NostrFilter(kinds: const [10030], authors: [pubkey], limit: 1)
      ],
      relays: _relayList,
    );
    List<String> emojiSetIds =
        emojiSetEvents.firstOrNull?.getTagValues('a') ?? [];
    if (emojiSetIds.isNotEmpty) {
      List<NostrFilter> emojiRequests = emojiSetIds
          .map((e) => NostrService.refIdToRequest(e))
          .whereType<NostrFilter>()
          .toList();
      final emojiEvents =
          await NostrService.instance.fetchEvents(emojiRequests);
      List<List<String>>? items;
      for (final event in emojiEvents) {
        items ??= [];
        items.addAll(event.getMatchedTags('emoji')?.toList() ?? []);
      }
      _emojiList = items;
    }
    return emojiList;
  }

  Future<DataRelayList> fetchRelayList([bool force = false]) async {
    if (!force && _relayList != null) {
      return relayList;
    }
    NostrService.instance.enableLogs();
    final items = await NostrService.instance
        .fetchUserRelayList(pubkey, relays: _relayList);
    NostrService.instance.disableLogs();
    _relayList = items;
    print('fetchRelayList: ${relayList.length}');
    return relayList;
  }

  Future<void> setFollowing(List<String> users) async {
    final event = DataEvent(
      kind: 3,
      tags: users.toSet().map((e) => ['p', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> unfollowAll() async {
    _following = [];
    await setFollowing(following);
  }

  Future<void> follow(String user) async {
    await fetchFollowing();
    if (!following.contains(user)) {
      _following ??= [];
      _following?.add(user);
    }
    await setFollowing(following);
  }

  Future<void> unfollow(String user) async {
    await fetchFollowing();
    if (following.contains(user)) {
      _following?.remove(user);
    }
    await setFollowing(following);
  }

  Future<void> mute(String user) async {
    await fetchMuteList();
    if (!muteList.contains(user)) {
      _muteList ??= [];
      _muteList?.add(user);
    }
    await setMuteList(muteList);
  }

  Future<void> unmute(String user) async {
    await fetchMuteList();
    if (muteList.contains(user)) {
      _muteList?.remove(user);
    }
    await setMuteList(muteList);
  }

  Future<void> setMuteList(List<String> users) async {
    final event = DataEvent(
      kind: 10000,
      tags: users.toSet().map((e) => ['p', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> unmuteAll() async {
    _muteList = [];
    await setMuteList(muteList);
  }

  Future<void> pin(String eventId) async {
    await fetchPinList();
    if (!pinList.contains(eventId)) {
      _pinList ??= [];
      _pinList?.add(eventId);
    }
    final event = DataEvent(
      kind: 10001,
      tags: pinList.toSet().map((e) => ['e', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> unpin(String eventId) async {
    await fetchPinList();
    if (pinList.contains(eventId)) {
      _pinList?.remove(eventId);
    }
    final event = DataEvent(
      kind: 10001,
      tags: pinList.toSet().map((e) => ['e', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> saveBookmark(String eventId) async {
    await fetchBookmarkList();
    if (!bookmarkList.contains(eventId)) {
      _bookmarkList ??= [];
      _bookmarkList?.add(eventId);
    }
    final event = DataEvent(
      kind: 10003,
      tags: bookmarkList.toSet().map((e) => ['e', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> deleteBookmark(String eventId) async {
    await fetchBookmarkList();
    if (bookmarkList.contains(eventId)) {
      _bookmarkList?.remove(eventId);
    }
    final event = DataEvent(
      kind: 10003,
      tags: bookmarkList.toSet().map((e) => ['e', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  Future<void> followHashtag(String hashtag) async {
    await fetchInterestSets();
    if (!interestSets.contains(hashtag)) {
      _interestSets ??= [];
      _interestSets?.add(hashtag);
    }
    await setInterestSets(interestSets);
  }

  Future<void> unFollowHashtag(String hashtag) async {
    await fetchInterestSets();
    if (interestSets.contains(hashtag)) {
      _interestSets?.remove(hashtag);
    }
    await setInterestSets(interestSets);
  }

  Future<void> unFollowHashtagAll() async {
    _interestSets = [];
    await setInterestSets(interestSets);
  }

  Future<void> setInterestSets(List<String> items) async {
    final event = DataEvent(
      kind: 10015,
      tags: interestSets.toSet().map((e) => ['t', e]).toList(),
    );
    await event.publish(relays: _relayList);
  }

  void initRelays(DataRelayList relays) {
    _relayList = relays;
  }

  Future<void> setRelays(DataRelayList relays) async {
    _relayList = relays;
    final event = DataEvent(
      kind: 10002,
      tags: relayList.toTags(),
    );
    await event.publish(relays: relayList);
  }

  Future<void> reportUser(String pubkey, [String type = "spam"]) async {
    // nudity - depictions of nudity, porn, etc.
    // malware - virus, trojan horse, worm, robot, spyware, adware, back door, ransomware, rootkit, kidnapper, etc.
    // profanity - profanity, hateful speech, etc.
    // illegal - something which may be illegal in some jurisdiction
    // spam - spam
    // impersonation - someone pretending to be someone else
    // other - for reports that don't fit in the above categories
    var event = DataEvent(kind: 1984, tags: [
      ['p', pubkey, type]
    ]);
    await event.publish(relays: _relayList);
  }

  Map<String, String?> toObject() {
    Map<String, String?> data = {};
    data['name'] = name;
    data['display_name'] = _displayName;
    data['nip05'] = nip05;
    data['website'] = website;
    data['image'] = image ?? picture;
    data['picture'] = picture ?? image;
    data['banner'] = banner;
    data['about'] = about;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    return data;
  }

  String toJson() {
    Map<String, String?> data = {};
    data['name'] = name;
    data['display_name'] = _displayName;
    data['nip05'] = nip05;
    data['website'] = website;
    data['image'] = image ?? picture;
    data['picture'] = picture ?? image;
    data['banner'] = banner;
    data['about'] = about;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    return jsonEncode(data);
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
    var content = toObject();
    content['picture'] = picture;
    content['banner'] = banner;
    content['name'] = name;
    content['display_name'] = displayName;
    content['about'] = about;
    content['website'] = website;
    content['lud06'] = lud06;
    content['lud16'] = lud16;
    content['nip05'] = nip05;
    var event = DataEvent(kind: 0, content: jsonEncode(content));
    await event.publish(relays: relays);
    this.picture = content['picture'];
    this.banner = content['banner'];
    this.name = content['name'];
    this.displayName = content['display_name'];
    this.about = content['about'];
    this.website = content['website'];
    this.lud06 = content['lud06'];
    this.lud16 = content['lud16'];
    this.nip05 = content['nip05'];
  }
}

class FollowSet {
  FollowSet({
    required this.type,
    required this.id,
    required this.name,
    required this.value,
  });

  final String type;
  final String id;
  final String name;
  final List<String> value;
}
