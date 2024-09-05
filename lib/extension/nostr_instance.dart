import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';

extension OutBoxModel on Nostr {
  Future<List<String?>> initRelays(DataRelayList relayList,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final futures = relayList.map((relay) async {
      return initRelay(relay, timeout: timeout);
    });
    return Future.wait(futures);
  }

  Future<String?> initRelay(DataRelay relay,
      {Duration timeout = const Duration(seconds: 5)}) {
    Completer<String?> completer = Completer<String?>();
    try {
      relaysService.relaysList ??= [];
      if (relaysService.nostrRegistry
          .isRelayRegisteredAndConnectedSuccesfully(relay.url)) {
        utils.log(
          'relay with url: ${relay.url} is already connected successfully, skipping...',
        );
        completer.complete(relay.url);
        return completer.future;
      }
      if (relaysService.relaysList?.contains(relay.url) != true) {
        relaysService.relaysList?.add(relay.url);
      }
      utils.log(
        'connecting to relay: ${relay.url}...',
      );
      relaysService.webSocketsService
          .connectRelay(
              relay: relay.url,
              shouldIgnoreConnectionException: false,
              onConnectionSuccess: (relayWebSocket) {
                relaysService.nostrRegistry.registerRelayWebSocket(
                  relayUrl: relay.url,
                  webSocket: relayWebSocket,
                );

                utils.log(
                  'the websocket for the relay with url: ${relay.url}, is registered.',
                );
                utils.log(
                  'listening to the websocket for the relay with url: ${relay.url}...',
                );
                relaysService.startListeningToRelay(
                  relay: relay.url,
                  retryOnError: true,
                  retryOnClose: false,
                  shouldReconnectToRelayOnNotice: true,
                  connectionTimeout: timeout,
                  ignoreConnectionException: false,
                  lazyListeningToRelays: false,
                  onNoticeMessageFromRelay: null,
                  onRelayListening: null,
                  onRelayConnectionError: null,
                  onRelayConnectionDone: null,
                );
                completer.complete(relay.url);
              })
          .catchError((e) => completer.completeError(e));
    } catch (e) {
      utils.log('onRelayConnectionError: ${relay.url}, $e');
      completer.completeError(relay.url);
    }
    return completer.future.timeout(timeout).onError((e, stack) {
      DataRelayList.failureList.add(DataRelay(url: relay.url));
      disposeRelay(relay.url);
      return relay.url;
    });
  }

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
      {Duration timeout = const Duration(seconds: 5),
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
    return DataRelayList.fromTags(events.elementAtOrNull(0)?.tags);
  }

  Future<List<DataEvent>> fetchEvents(
    List<NostrFilter> filters, {
    double eoseRatio = 1.2,
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
          completer.complete(items);
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
