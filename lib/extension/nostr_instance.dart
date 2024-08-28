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
        completer.complete();
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
          .catchError((e) => completer.completeError(relay.url));
    } catch (e) {
      completer.completeError(relay.url);
      utils.log('onRelayConnectionError: ${relay.url}, $e');
    }
    return completer.future.timeout(timeout).onError((e, stack) {
      disposeRelay(relay.url);
      return null;
    });
  }

  Future<void> disposeRelay(String relayUrl) async {
    try {
      utils.log('dispose relay: $relayUrl');
      relaysService.nostrRegistry.relaysWebSocketsRegistry[relayUrl]?.sink
          .close();
      relaysService.nostrRegistry.unregisterRelay(relayUrl);
    } catch (err) {
      utils.log('dispose relay: $relayUrl', err);
    }
    relaysService.relaysList?.remove(relayUrl);
  }

  Future<DataRelayList> fetchUserRelayList(String pubkey,
      {Duration timeout = const Duration(seconds: 5),
      DataRelayList? relays}) async {
    List<NostrFilter> request = [
      NostrFilter(kinds: const [10002], authors: [pubkey], limit: 1),
    ];
    final events = await fetchEvents(
      request,
      eoseRatio: 1,
      timeout: timeout,
      relays: relays,
    );
    events.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return DataRelayList.fromTags(events.elementAtOrNull(0)?.tags);
  }

  Future<List<DataEvent>> fetchEvents(
    List<NostrFilter> filters, {
    double eoseRatio = 1,
    DataRelayList? relays,
    Duration timeout = const Duration(seconds: 3),
    bool isAscending = false,
  }) async {
    final readRelays = relays != null
        ? AppRelays.relays.clone().concat(relays).readRelays
        : null;
    int eose = 0;
    final completer = Completer<List<DataEvent>>();
    Map<String, DataEvent> events = {};
    final request = NostrRequest(filters: filters);
    int relayLength = readRelays?.length ?? relaysService.relaysList!.length;
    NostrEventsStream nostrStream = relaysService.startEventsSubscription(
      request: request,
      relays: readRelays,
      onEose: (relay, ease) {
        eose += 1;
        try {
          relaysService.closeEventsSubscription(ease.subscriptionId, relay);
        } catch (err) {}
        if (completer.isCompleted) return;
        if (eose >= relayLength / eoseRatio) {
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
      var e = DataEvent.fromEvent(event);
      var id = e.id!;
      if (e.kind! >= 30000) {
        id =
            '${e.kind}:${e.pubkey}:${e.tags!.firstWhere((e) => e.first == 'd').elementAtOrNull(1)}';
      }
      if (events.containsKey(id) && events[id]!.createdAt != null) {
        if (events[id]!.createdAt!.compareTo(e.createdAt!) < 0) {
          NostrService.eventList[id] = e;
          events[id] = e;
        }
      } else {
        NostrService.eventList[id] = e;
        events[id] = e;
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
