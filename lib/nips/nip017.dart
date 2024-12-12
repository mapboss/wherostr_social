import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/nips/nip004.dart';
import 'package:wherostr_social/nips/nip044.dart';
import 'package:wherostr_social/nips/nip059.dart';

/// Private Direct Messages
/// https://github.com/nostr-protocol/nips/blob/master/17.md
class Nip17 {
  static Future<NostrEvent> encode(
      NostrEvent event, String receiver, String myPubkey, String privkey,
      {int? kind,
      int? expiration,
      String? sealedPrivkey,
      String? sealedReceiver,
      DateTime? createAt}) async {
    NostrEvent sealedGossipEvent = await _encodeSealedGossip(
        event, sealedReceiver ?? receiver, myPubkey, privkey);
    return await Nip59.encode(sealedGossipEvent, sealedReceiver ?? receiver,
        kind: kind?.toString(),
        expiration: expiration,
        sealedPrivkey: sealedPrivkey,
        createAt: createAt);
  }

  static Future<NostrEvent> _encodeSealedGossip(NostrEvent event,
      String receiver, String myPubkey, String privkey) async {
    String encodedEvent = jsonEncode(event.toMap());
    String content =
        await Nip44.encrypt(encodedEvent, Nip44.shareSecret(privkey, receiver));

    print('fromPartialData');
    return NostrEvent.fromPartialData(
      kind: 13,
      tags: [],
      createdAt: randomTimeUpTo2DaysInThePast(),
      content: content,
      keyPairs: NostrKeyPairs(private: privkey),
    );
  }

  static Future<NostrEvent> encodeInnerEvent(String receiver, String content,
      String replyId, String myPubkey, String privKey,
      {String? subContent,
      int? expiration,
      List<String>? members,
      String? subject,
      DateTime? createAt}) async {
    List<List<String>> tags =
        Nip4.toTags(receiver, replyId, expiration, members: members);
    if (subContent != null && subContent.isNotEmpty) {
      tags.add(['subContent', subContent]);
    }
    if (subject != null && subject.isNotEmpty) {
      tags.add(['subject', subject]);
    }
    return NostrEvent.fromPartialData(
        kind: 14,
        tags: tags,
        content: content,
        keyPairs: NostrKeyPairs(private: privKey),
        createdAt: createAt);
  }

  static Future<NostrEvent> encodeSealedGossipDM(String receiver,
      String content, String replyId, String myPubkey, String privKey,
      {String? sealedPrivkey,
      String? sealedReceiver,
      DateTime? createAt,
      String? subContent,
      int? expiration,
      NostrEvent? innerEvent,
      List<String>? members}) async {
    try {
      innerEvent ??= await encodeInnerEvent(
          receiver, content, replyId, myPubkey, privKey,
          subContent: subContent, expiration: expiration);
      NostrEvent event = await encode(innerEvent, receiver, myPubkey, privKey,
          sealedPrivkey: sealedPrivkey,
          sealedReceiver: sealedReceiver,
          createAt: createAt,
          expiration: expiration);
      // event.innerEvent = DataEvent.fromEvent(innerEvent);
      return event;
    } catch (err) {
      print(err);
      throw err;
    }
  }

  static Future<DataEvent> decode(NostrEvent event, String privkey,
      {String? sealedPrivkey}) async {
    DataEvent sealedGossipEvent =
        await Nip59.decode(event, sealedPrivkey ?? privkey);
    DataEvent decodeEvent =
        await _decodeSealedGossip(sealedGossipEvent, sealedPrivkey ?? privkey);
    return decodeEvent;
  }

  static Future<DataEvent> _decodeSealedGossip(
      DataEvent event, String privkey) async {
    if (event.kind == 13) {
      try {
        String content = await Nip44.decrypt(
            event.content!, Nip44.shareSecret(privkey, event.pubkey));
        Map<String, dynamic> map = jsonDecode(content);
        map['sig'] = '';
        DataEvent innerEvent = DataEvent.fromJson(map);
        if (innerEvent.pubkey == event.pubkey) {
          return innerEvent;
        }
      } catch (e) {
        throw Exception(e);
      }
    }
    throw Exception("${event.kind} is not nip24 compatible");
  }

  static Future<EDMessage?> decodeSealedGossipDM(
      DataEvent innerEvent, String receiver) async {
    if (innerEvent.kind == 14) {
      List<String> receivers = [];
      String replyId = "";
      String? subContent = innerEvent.content;
      String? expiration;
      String? subject;
      for (var tag in innerEvent.tags ?? []) {
        if (tag[0] == "p") {
          if (!receivers.contains(tag[1])) receivers.add(tag[1]);
        }
        if (tag[0] == "e") replyId = tag[1];
        if (tag[0] == "subContent") subContent = tag[1];
        if (tag[0] == "expiration") expiration = tag[1];
        if (tag[0] == "subject") subject = tag[1];
      }
      if (receivers.length == 1) {
        // private chat
        return EDMessage(innerEvent.pubkey, receivers.first,
            innerEvent.createdAt, subContent, replyId, expiration);
      } else {
        // private chat room
        return EDMessage(innerEvent.pubkey, '', innerEvent.createdAt,
            subContent, replyId, expiration,
            groupId: ChatRoom.generateChatRoomID(receivers),
            subject: subject,
            members: receivers);
      }
    }
    return null;
  }

  static Future<DataEvent> encodeDMRelays(
      List<String> relays, String myPubkey, String privkey) async {
    List<List<String>> tags = [];
    for (var relay in relays) {
      tags.add(['relay', relay]);
    }
    return DataEvent.fromEvent(NostrEvent.fromPartialData(
      kind: 10050,
      tags: tags,
      content: '',
      keyPairs: NostrKeyPairs(private: privkey),
    ));
  }

  static List<String> decodeDMRelays(DataEvent event) {
    if (event.kind == 10050) {
      List<String> result = [];
      for (var tag in event.tags ?? []) {
        if (tag[0] == 'relay') result.add(tag[1]);
      }
      return result;
    }
    throw Exception("${event.kind} is not nip17 compatible");
  }

  static DateTime randomTimeUpTo2DaysInThePast() {
    final intValue = Random().nextInt(24 * 60 * 60 * 2);
    return DateTime.now().subtract(Duration(seconds: intValue));
  }
}

/// ChatRoom info
class ChatRoom {
  String id;
  String name;
  List<String> members;

  /// Default constructor
  ChatRoom(this.id, this.name, this.members);

  static String generateChatRoomID(List<String> members) {
    members.sort();
    String concatenatedPubkeys = members.join();
    var bytes = utf8.encode(concatenatedPubkeys);
    var digest = crypto.md5.convert(bytes);
    return digest.toString();
  }
}
