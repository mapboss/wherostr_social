import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';

extension OutBoxModel on Nostr {
  Future<void> disposeRelay(String relayUrl) async {
    try {
      utils.log('dispose relay: $relayUrl');
      relaysService.nostrRegistry.relaysWebSocketsRegistry[relayUrl]?.sink
          .close();
      relaysService.nostrRegistry.unregisterRelay(relayUrl);
      relaysService.relaysList?.remove(relayUrl);
      utils.log('dispose relay: $relayUrl done.');
    } catch (err) {
      utils.log('dispose relay: $relayUrl', err);
    }
  }

  Future<DataRelayList> fetchUserRelayList(String pubkey,
      {Duration timeout = const Duration(seconds: 3),
      DataRelayList? relays}) async {
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10002], authors: [pubkey], limit: 1),
    ];
    final events = await fetchEvents(
      request,
      timeout: timeout,
      relays: relays,
    );
    events.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return DataRelayList.fromEvent(events.elementAtOrNull(0));
  }

  Future<List<DataEvent>> fetchEvents(
    List<NostrFilter> filters, {
    double eoseRatio = 1.5,
    DataRelayList? relays,
    Duration timeout = const Duration(seconds: 5),
    bool isAscending = false,
  }) async {
    final readRelays = relays
        ?.clone()
        .leftCombine(AppRelays.relays)
        .leftCombine(AppRelays.defaults)
        .readRelays;
    int eose = 0;
    final completer = Completer<List<DataEvent>>();
    Map<String, DataEvent> events = {};
    final request = NostrRequest(filters: filters);
    int relayLength = readRelays?.length ?? relaysService.relaysList!.length;
    NostrEventsStream nostrStream = relaysService.startEventsSubscription(
      request: request,
      relays: readRelays ?? relaysService.relaysList,
      onEose: (relay, ease) {
        eose += 1;
        try {
          // if (events.values.firstOrNull?.kind == 3) {
          //   print(
          //       'events: ${events.values.firstOrNull?.getTagValues('p')?.length}, $relay');
          // }
          // relaysService.closeEventsSubscription(ease.subscriptionId);
          relaysService.closeEventsSubscription(ease.subscriptionId, relay);
        } catch (err) {}
        if (completer.isCompleted) return;
        if (events.values.isNotEmpty || eose >= relayLength * eoseRatio) {
          final items = events.values.toList();
          if (isAscending == false) {
            items.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
          } else {
            items.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
          }
          relaysService.closeEventsSubscription(ease.subscriptionId);
          if (!completer.isCompleted) {
            completer.complete(items);
          }
        }
      },
    );
    var sub = nostrStream.stream.listen((event) {
      try {
        final e = DataEvent.fromEvent(event);
        String id = e.getId()!;
        if (events.containsKey(id) && events[id]!.createdAt != null) {
          if (events[id]!.createdAt!.compareTo(e.createdAt!) < 0) {
            NostrService.eventList[id] = e;
            events[id] = e;
          }
        } else {
          NostrService.eventList[id] = e;
          events[id] = e;
        }
      } catch (err) {
        print('err: $err');
      }
    });
    return completer.future.timeout(timeout, onTimeout: () {
      final items = events.values.toList();
      if (isAscending == false) {
        items.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      } else {
        items.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
      }
      return items;
    }).whenComplete(() {
      sub.cancel().whenComplete(() {
        nostrStream.close();
      });
    });
  }
}
