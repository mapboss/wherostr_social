import 'dart:async';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_event.dart';

Stream<String> minePoW(DataEvent unsigned,
    {int targetDifficulty = 12, int nonceStart = 0, int index = 0}) async* {
  int count = nonceStart;
  int bestDiff = 0;
  final event = DataEvent.fromJson(unsigned.toMap());
  final tag = ['nonce', count.toString(), targetDifficulty.toString()];
  event.tags?.add(tag);
  while (true) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final current = (event.createdAt?.millisecondsSinceEpoch ?? 0) ~/ 1000;
    if (now != current) {
      count = nonceStart;
      event.createdAt = DateTime.fromMillisecondsSinceEpoch(now * 1000);
    }
    tag[1] = (++count).toString();
    final hash = event.generateEventId();
    int currentDiff = Nostr.instance.utilsService.countDifficultyOfHex(hash);
    if (currentDiff >= targetDifficulty) {
      yield '$hash|$count|${event.createdAt?.millisecondsSinceEpoch}|$index';
    } else if (currentDiff >= bestDiff) {
      bestDiff = currentDiff;
      yield '$hash|$count|${event.createdAt?.millisecondsSinceEpoch}|$index';
    }
    // Allow the event loop to run by yielding control back to the main thread
    await Future.delayed(Duration.zero);
  }
}

Future<String> isolateMinePoW(DataEvent event,
    {int isolateCount = 1, int targetDifficulty = 12}) async {
  List<Stream> streams = [];
  final completer = Completer<String>();
  for (int i = 0; i < isolateCount; i++) {
    final stream = minePoW(event,
        targetDifficulty: targetDifficulty, nonceStart: (i * 20000), index: i);
    streams.add(stream);
  }
  int bestDiff = 0;
  int currentDiff = 0;
  Future.wait(streams.map((stream) async {
    await for (final result in stream) {
      if (completer.isCompleted) {
        break;
      }
      final [hash, nonce, date, index] = result.split('|');
      currentDiff = Nostr.instance.utilsService.countDifficultyOfHex(hash);
      if (currentDiff >= targetDifficulty) {
        completer.complete(result);
      } else if (currentDiff >= bestDiff) {
        bestDiff = currentDiff;
        print('best hash: $hash, index: $index');
      }
    }
  }));
  return completer.future;
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
