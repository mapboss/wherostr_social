import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wherostr_social/models/data_message.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/models/nostr_user.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip017.dart';
import 'package:wherostr_social/services/nostr.dart';

class MessageService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    MessageService.isar = Isar.openSync(
      [DataMessageSchema],
      directory: dir.path,
    );
  }

  static Completer<void> sync(NostrKeyPairs keyPairs, NostrUser me) {
    final completer = Completer<void>();
    final List<NostrFilter> filters = [];
    Future.wait([
      MessageService.isar.dataMessages
          .where()
          .sortByCreatedAtDesc()
          .limit(1)
          .findFirst(),
      me.fetchDMRelayList()
    ]).then((v) {
      final DataMessage? latest = v[0] as DataMessage?;
      final DataRelayList? relays = v[1] as DataRelayList?;
      final createdAt = latest?.createdAt;
      filters.add(NostrFilter(
        kinds: [1059],
        p: [me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .subtract(Duration(days: 2)),
      ));
      filters.add(NostrFilter(
        kinds: [4],
        p: [me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .add(Duration(milliseconds: 1000)),
      ));
      filters.add(NostrFilter(
        kinds: [4],
        authors: [me.pubkey],
        since: createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(createdAt)
                .add(Duration(milliseconds: 1000)),
      ));
      final newEventStream = NostrService.subscribe(
        filters,
        relays: relays,
        onEose: (relay, ease) async {
          print('onEose: $relay');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      final newEventListener = newEventStream.stream.listen((e) async {
        var newEvent = e;
        if (e.kind == 1059) {
          final event = await Nip17.decode(newEvent, keyPairs.private);
          MessageService.isar.writeTxnSync(() {
            MessageService.isar.dataMessages.putSync(DataMessage(
              createdAt: event.createdAt!.millisecondsSinceEpoch,
              eventId: event.id!,
              plainText: event.content!,
              sender: event.pubkey,
              receiver: event.getTagValue('p')!,
              replyId: event.getTagValue('e'),
            ));
          });
        } else if (e.kind == 4) {
          final msg =
              await Nip4.decode(newEvent, keyPairs.public, keyPairs.private);
          MessageService.isar.writeTxnSync(() {
            MessageService.isar.dataMessages.putSync(DataMessage(
              createdAt: msg!.createdAt!.millisecondsSinceEpoch,
              eventId: newEvent.id!,
              plainText: msg.content!,
              sender: msg.sender,
              receiver: msg.receiver,
              replyId: msg.replyId,
            ));
          });
        }
      });
      completer.future.whenComplete(() {
        newEventStream.close();
        newEventListener.cancel();
      });
    });
    return completer;
  }
}
