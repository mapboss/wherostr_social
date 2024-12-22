import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';

/// HTTP Auth
class Nip98 {
  static NostrEvent encode(String url, String method, NostrKeyPairs keyPairs) {
    List<List<String>> tags = [];
    tags.add(['u', url]);
    tags.add(['method', method.toUpperCase()]);
    return NostrEvent.fromPartialData(
      kind: 27235,
      tags: tags,
      content: '',
      keyPairs: keyPairs,
    );
  }

  static String base64Event(String url, String method, NostrKeyPairs keyPairs) {
    NostrEvent event = encode(url, method, keyPairs);
    final jsonString = jsonEncode(event.toMap());
    List<int> bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }
}
