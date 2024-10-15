import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/nips/nip044.dart';

/// Gift Wrap
/// https://github.com/v0l/nips/blob/59/59.md
class Nip59 {
  static Future<DataEvent> encode(DataEvent event, String receiver,
      {String? sealedPrivkey,
      String? kind,
      int? expiration,
      DateTime? createAt}) async {
    String encodedEvent = jsonEncode(event);
    late NostrKeyPairs keychain;
    if (sealedPrivkey == null) {
      keychain = NostrKeyPairs.generate();
      sealedPrivkey = keychain.private;
    } else {
      keychain = NostrKeyPairs(private: sealedPrivkey);
    }
    Nip44.shareSecret(sealedPrivkey, receiver);
    String content = await Nip44.encrypt(
        encodedEvent, Nip44.shareSecret(keychain.private, receiver));
    List<List<String>> tags = [
      ["p", receiver]
    ];
    if (kind != null) tags.add(['k', kind]);
    if (expiration != null) tags.add(['expiration', '$expiration']);
    return DataEvent.fromEvent(NostrEvent.fromPartialData(
        kind: 1059,
        tags: tags,
        content: content,
        keyPairs: keychain,
        createdAt: createAt ?? DateTime.now()));
  }

  static Future<DataEvent> decode(DataEvent event, String privkey) async {
    if (event.kind == 1059) {
      String content = await Nip44.decrypt(
          event.content!, Nip44.shareSecret(privkey, event.pubkey));
      Map<String, dynamic> map = jsonDecode(content);
      return DataEvent.fromJson(map);
    }
    throw Exception("${event.kind} is not nip59 compatible");
  }
}
