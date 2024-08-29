import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_event.dart';

Future<Completer<DataEvent>> minePow(DataEvent unsigned,
    [int targetDifficulty = 12]) async {
  int count = 0;

  final event = unsigned;
  final tag = ['nonce', count.toString(), targetDifficulty.toString()];

  event.tags?.add(tag);
  Completer<DataEvent> completer = Completer();
  while (true) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now != event.createdAt?.millisecondsSinceEpoch) {
      count = 0;
      event.createdAt = DateTime.fromMillisecondsSinceEpoch(now);
    }
    tag[1] = (++count).toString();
    event.id = event.generateEventId();
    int currentDiff =
        Nostr.instance.utilsService.countDifficultyOfHex(event.id!);
    if (currentDiff >= targetDifficulty) {
      break;
    }
    // Allow the event loop to run by yielding control back to the main thread
    await Future.delayed(Duration.zero);
  }
  return completer;
}

int getDifficulty(NostrEvent event) {
  List<String>? nonce =
      event.tags?.where((tag) => tag[0] == 'nonce').firstOrNull;
  int difficulty = Nostr.instance.utilsService.countDifficultyOfHex(event.id!);
  return nonce?.elementAtOrNull(1) != null && difficulty > 0 ? difficulty : 0;
}
