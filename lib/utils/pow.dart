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
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final current = (event.createdAt?.millisecondsSinceEpoch ?? 0) ~/ 1000;

    if (now != current) {
      count = 0;
      event.createdAt = DateTime.fromMillisecondsSinceEpoch(now * 1000);
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

String difficultyToHex(int difficulty, [bool? onlyZero = false]) {
  // Calculate how many full hex digits are required for the given difficulty
  int fullHexDigits = difficulty ~/ 4;
  int remainingBits = difficulty % 4;

  // Start with the required number of full hex digits
  String hexString = '0' * fullHexDigits;

  // If there are remaining bits, calculate the next hex digit
  if (remainingBits > 0) {
    // This will be the highest possible value under the remaining bits
    int remainingValue = (1 << (4 - remainingBits)) - 1;
    hexString += remainingValue.toRadixString(16);
  }

  final hexResult = onlyZero == true
      ? hexString.replaceAll(r'[1-9][a-f][A-F]', '')
      : hexString;

  return hexResult;
}
