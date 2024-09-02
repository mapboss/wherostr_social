import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/extension/nostr_instance.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/nostr_user.dart';

final searchRelays = DataRelayList.fromListString([
  'wss://relay.nostr.band/all',
  'wss://nostr.wine',
  // 'wss://relay.roli.social',
  // 'wss://relay.rushmi0.win',
]);
final countRelays = DataRelayList.fromListString([
  'wss://relay.nostr.band',
  // 'wss://relay.roli.social',
  // 'wss://relay.rushmi0.win',
]);

class NostrService {
  static Nostr instance = Nostr();
  static Nostr searchInstance = Nostr();
  static Nostr countInstance = Nostr();
  static Map<String, DataEvent> eventList = {};
  static Map<String, NostrUser> profileList = {};

  static NostrFilter? refIdToRequest(String ref) {
    var refs = ref.split(':');
    var kindString = refs.elementAtOrNull(0);
    var pubkey = refs.elementAtOrNull(1);
    var identifier = refs.elementAtOrNull(2);
    if (kindString != null && pubkey != null && identifier != null) {
      return NostrFilter(
        kinds: [int.parse(kindString)],
        authors: [pubkey],
        limit: 1,
        additionalFilters: {
          "#d": [identifier]
        },
      );
    }
    return null;
  }

  static Future<int> countEvent(NostrFilter filter) async {
    try {
      countInstance.enableLogs();
      final countEvent = NostrCountEvent.fromPartialData(eventsFilter: filter);
      Completer<NostrCountResponse> completer = Completer();
      countInstance.relaysService.sendCountEventToRelays(
        countEvent,
        onCountResponse: (relay, countResponse) =>
            completer.complete(countResponse),
      );
      return completer.future.then((v) => v.count);
    } catch (err) {
      print('countEvent: $err');
    }
    return 0;
  }

  static Future<DataEvent?> fetchEventById(
    String id, {
    DataRelayList? relays,
    double eoseRatio = 1,
    Nostr? instance,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    instance ??= NostrService.instance;
    final cache = NostrService.eventList[id];
    if (cache != null) {
      return cache;
    }
    final request = refIdToRequest(id);
    if (request != null) {
      return instance.fetchEvents(
        [request],
        relays: relays,
        eoseRatio: 1,
        timeout: timeout,
      ).then((v) => v.firstOrNull);
    }
    return fetchEventIds(
      [id],
      relays: relays,
      eoseRatio: eoseRatio,
      instance: instance,
      timeout: timeout,
    ).then((value) => value.firstOrNull);
  }

  static Future<List<DataEvent>> fetchEventIds(
    List<String> ids, {
    DataRelayList? relays,
    double eoseRatio = 1,
    Nostr? instance,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    instance ??= NostrService.instance;
    final idSet = ids.toSet();
    final idList = idSet.toList();
    final events = idSet.map((id) {
      var cache = NostrService.eventList[id];
      if (cache != null) {
        idList.remove(id);
      }
      return cache;
    }).whereType<DataEvent>();

    if (events.length == idSet.length) {
      print('fetchEventIds: use cache: ${events.length == idSet.length}');
      return events.toList();
    }

    print(
        'fetchEventIds: use cache: ${events.length}, no cache: ${idList.length}');

    List<NostrFilter> filters = [];
    List<String> idFilters = [];
    for (final id in idList) {
      final filter = refIdToRequest(id);
      if (filter != null) {
        filters.add(filter);
      }
      idFilters.add(id);
    }
    if (idFilters.isNotEmpty) {
      filters.add(NostrFilter(ids: idFilters, limit: idFilters.length));
    }
    final result = await instance.fetchEvents(
      filters,
      relays: relays,
      eoseRatio: eoseRatio,
      timeout: timeout,
    );
    result.addAll(events);
    return result;
  }

  static Future<List<DataEvent>> fetchEvents(
    List<NostrFilter> filters, {
    DataRelayList? relays,
    double eoseRatio = 1,
    Nostr? instance,
    Duration timeout = const Duration(seconds: 3),
    bool isAscending = false,
  }) async {
    instance ??= NostrService.instance;
    return instance.fetchEvents(
      filters,
      relays: relays,
      eoseRatio: eoseRatio,
      timeout: timeout,
      isAscending: isAscending,
    );
  }

  static Future<List<NostrUser>> _fetchUsers(
    List<String> pubkeyList, {
    Duration timeout = const Duration(seconds: 3),
    DataRelayList? relays,
  }) async {
    final readRelays = relays?.clone().leftCombine(AppRelays.relays).readRelays;
    int eose = 0;
    final completer = Completer<List<NostrUser>>();
    Map<String, NostrUser> events = {};
    final request = NostrRequest(filters: [
      NostrFilter(
          kinds: const [0], authors: pubkeyList, limit: pubkeyList.length)
    ]);
    NostrEventsStream nostrStream =
        NostrService.instance.relaysService.startEventsSubscription(
      request: request,
      relays: readRelays,
      onEose: (relay, ease) {
        eose += 1;
        try {
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId, relay);
        } catch (err) {}
        if (completer.isCompleted == true) return;
        if (eose >= readRelays!.length) {
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId);
          completer.complete(events.values.toList());
        }
      },
    );
    var sub = nostrStream.stream.listen((event) {
      if (events.containsKey(event.pubkey) &&
          events[event.pubkey]!.createdAt != null) {
        if (events[event.pubkey]!.createdAt!.compareTo(event.createdAt!) < 0) {
          final userJson = jsonDecode(event.content!);
          userJson['pubkey'] = event.pubkey;
          userJson['createdAt'] = event.createdAt;
          events[event.pubkey] = NostrUser.fromJson(userJson);
          NostrService.profileList[event.pubkey] = events[event.pubkey]!;
        }
      } else {
        final userJson = jsonDecode(event.content!);
        userJson['pubkey'] = event.pubkey;
        userJson['createdAt'] = event.createdAt;
        events[event.pubkey] = NostrUser.fromJson(userJson);
        NostrService.profileList[event.pubkey] = events[event.pubkey]!;
      }
    });
    return completer.future.timeout(timeout, onTimeout: () {
      return pubkeyList.map((e) {
        if (NostrService.profileList.containsKey(e)) {
          return NostrService.profileList[e]!;
        }
        NostrService.profileList[e] = NostrUser(pubkey: e);
        return NostrService.profileList[e]!;
      }).toList();
    }).whenComplete(() {
      sub.cancel().whenComplete(() {
        nostrStream.close();
      });
    });
  }

  static Future<List<NostrUser>> fetchUsers(
    List<String> pubkeyList, {
    Duration timeout = const Duration(seconds: 3),
    DataRelayList? relays,
  }) async {
    final pubkeySet = pubkeyList.toSet();
    final clonePubkeyList = pubkeySet.toList();
    final users = pubkeySet.map((pubkey) {
      var cache = NostrService.profileList[pubkey];
      if (cache != null && (cache.rawDisplayName?.isNotEmpty ?? false)) {
        clonePubkeyList.remove(pubkey);
      }
      return cache;
    }).whereType<NostrUser>();

    if (users.length == pubkeySet.length) {
      print('fetchUsers: use cache: ${users.length == pubkeySet.length}');
      return users.toList();
    }

    print(
        'fetchUsers: use cache: ${users.length}, no cache: ${clonePubkeyList.length}');

    final result = await _fetchUsers(
      clonePubkeyList,
      timeout: timeout,
      relays: relays,
    );
    result.addAll(users);
    return result;
  }

  static Future<NostrUser> _fetchUser(
    String pubkey, {
    Duration timeout = const Duration(seconds: 3),
    DataRelayList? relays,
  }) async {
    final readRelays = relays?.clone().leftCombine(AppRelays.relays).readRelays;
    int eose = 0;
    final completer = Completer<NostrUser>();
    Map<String, NostrUser> events = {};
    final request = NostrRequest(filters: [
      NostrFilter(kinds: const [0], authors: [pubkey], limit: 1)
    ]);
    NostrEventsStream nostrStream =
        NostrService.instance.relaysService.startEventsSubscription(
      request: request,
      relays: readRelays,
      onEose: (relay, ease) {
        eose += 1;
        try {
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId, relay);
        } catch (err) {}
        if (completer.isCompleted == true) return;
        if (events.isNotEmpty) {
          NostrService.profileList[pubkey] = events.values.first;
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId);
          return completer.complete(events.values.first);
        }
        if (eose >= readRelays!.length) {
          NostrService.profileList[pubkey] = NostrUser(pubkey: pubkey);
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId);
          completer.complete(NostrService.profileList[pubkey]);
        }
      },
    );
    var sub = nostrStream.stream.listen((event) {
      if (events[event.pubkey] != null &&
          events[event.pubkey]!.createdAt != null) {
        if (events[event.pubkey]!.createdAt!.compareTo(event.createdAt!) < 0) {
          events[event.pubkey] = NostrUser.fromEvent(event);
          NostrService.profileList[event.pubkey] = events[event.pubkey]!;
        }
      } else {
        events[event.pubkey] = NostrUser.fromEvent(event);
        NostrService.profileList[event.pubkey] = events[event.pubkey]!;
      }
    });
    return completer.future.timeout(timeout, onTimeout: () {
      return NostrUser(pubkey: pubkey);
    }).whenComplete(() {
      sub.cancel().whenComplete(() {
        nostrStream.close();
      });
    });
  }

  static Future<NostrUser> fetchUser(
    String pubkey, {
    bool force = false,
    Duration timeout = const Duration(seconds: 3),
    DataRelayList? relays,
  }) async {
    if (!force && NostrService.profileList.containsKey(pubkey)) {
      return NostrService.profileList[pubkey]!;
    }
    return _fetchUser(pubkey, timeout: timeout, relays: relays);
  }

  static NostrEventsStream subscribe(
    List<NostrFilter> filters, {
    DataRelayList? relays,
    bool? closeOnEnd,
    String? subscriptionId,
    bool useConsistentSubscriptionIdBasedOnRequestData = false,
    Duration timeout = const Duration(seconds: 5),
    Function()? onEnd,
  }) {
    Completer? completer;
    final readRelays =
        relays?.clone().leftCombine(AppRelays.relays).readRelays ??
            NostrService.instance.relaysService.relaysList!;
    final request =
        NostrRequest(filters: filters, subscriptionId: subscriptionId);

    int eose = 0;
    NostrEventsStream nostrStream =
        NostrService.instance.relaysService.startEventsSubscription(
      useConsistentSubscriptionIdBasedOnRequestData:
          useConsistentSubscriptionIdBasedOnRequestData,
      request: request,
      relays: readRelays,
      onEose: (relay, ease) {
        eose += 1;

        if (closeOnEnd ?? false) {
          if (completer == null) {
            completer = Completer();
            completer?.future.timeout(timeout).whenComplete(() {
              onEnd?.call();
            });
          }
          NostrService.instance.relaysService
              .closeEventsSubscription(ease.subscriptionId, relay);
        }
        if (eose >= readRelays.length) {
          completer?.complete();
        }
      },
    );
    return nostrStream;
  }

  static Future<DataRelayList> initWithNpubOrPubkey(String npubOrPubkey,
      [Duration timeout = const Duration(seconds: 5)]) async {
    instance = Nostr();
    await Future.wait([
      instance.initRelays(
        AppRelays.relays,
        timeout: timeout,
      ),
    ]);
    searchInstance.initRelays(
      searchRelays,
      timeout: timeout,
    );
    countInstance.initRelays(
      countRelays,
      timeout: timeout,
    );
    String pubkey = '';
    if (npubOrPubkey.startsWith('npub1')) {
      pubkey = instance.keysService.decodeNpubKeyToPublicKey(npubOrPubkey);
    } else {
      pubkey = npubOrPubkey;
    }
    DataRelayList relays =
        await instance.fetchUserRelayList(pubkey, timeout: timeout);
    if (relays.isEmpty) {
      // AppUtils.showSnackBar(
      //   text: "No relays specified. Using default relays.",
      //   status: AppStatus.warning,
      // );
      relays = AppRelays.relays;
    } else {
      await instance.initRelays(relays, timeout: timeout);
    }
    instance.disableLogs();
    return relays;
  }

  static Future<List<DataEvent>> search(String keyword,
      {List<int> kinds = const [0], int limit = 20}) async {
    // if (searchInstance
    //         .relaysService.nostrRegistry.relaysWebSocketsRegistry.isEmpty !=
    //     false) {
    //   searchInstance.enableLogs();
    //   await searchInstance.initRelays(searchRelays);
    //   // searchInstance.disableLogs();
    // }
    return searchInstance.fetchEvents(
      [NostrFilter(search: keyword, kinds: kinds, limit: limit)],
      timeout: const Duration(seconds: 10),
    );
  }
}
