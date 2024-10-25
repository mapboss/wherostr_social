import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_event.dart';

/// HTTP Auth
class Nip98 {
  static DataEvent encode(String url, String method, NostrKeyPairs keyPairs) {
    List<List<String>> tags = [];
    tags.add(['u', url]);
    tags.add(['method', method.toUpperCase()]);
    return DataEvent.fromEvent(NostrEvent.fromPartialData(
      kind: 27235,
      tags: tags,
      content: '',
      keyPairs: keyPairs,
    ));
  }

  static String base64Event(String url, String method, NostrKeyPairs keyPairs) {
    DataEvent event = encode(url, method, keyPairs);
    String jsonString = jsonEncode(event.toJson());
    List<int> bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }
}
