// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:text_parser/text_parser.dart';
import 'package:wherostr_social/models/app_relays.dart';
import 'package:wherostr_social/models/app_secret.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/pow.dart';
import 'package:wherostr_social/utils/safe_parser.dart';
import 'package:wherostr_social/utils/text_parser.dart';

TextParser emojiParser = TextParser(matchers: [const CustomEmojiMatcher()]);
TextParser contentParser = TextParser(matchers: [
  const CustomEmojiMatcher(),
  const NostrLinkMatcher(),
  const HashTagMatcher()
]);

class DataEvent extends NostrEvent {
  @override
  String pubkey = '';

  @override
  String? sig;

  @override
  String? id;

  @override
  DateTime? createdAt = DateTime.timestamp();

  @override
  String? content = '';

  @override
  List<List<String>>? tags = [];

  @override
  int? kind;

  final List<DataEvent> relatedEvents = [];

  Map<String, List<List<String>>>? _tagIndex;
  Map<String, List<List<String>>> get tagIndex => _tagIndex ?? {};

  DataEvent({
    this.pubkey = '',
    this.kind,
    this.createdAt,
    this.id,
    this.sig,
    this.content,
    this.tags,
    super.subscriptionId,
  }) : super(
          id: id ?? '',
          pubkey: pubkey,
          tags: tags ?? [],
          sig: sig ?? '',
          content: content ?? '',
          kind: kind,
          createdAt: createdAt ?? DateTime.timestamp(),
        );

  factory DataEvent.deserialized(String data) =>
      DataEvent.fromEvent(NostrEvent.deserialized(data));

  factory DataEvent.fromEvent(NostrEvent data) {
    final tagsToUse = data.tags ?? [];
    final createdAtToUse = data.createdAt ?? DateTime.timestamp();
    final contentToUse = SafeParser.parseString(data.content);
    final kindToUse = SafeParser.parseInt(data.kind);
    final pubkeyToUse = SafeParser.parseString(data.pubkey);
    final id = SafeParser.parseString(data.id);

    return DataEvent(
      id: id,
      pubkey: pubkeyToUse ?? '',
      kind: kindToUse,
      content: contentToUse ?? '',
      createdAt: createdAtToUse,
      tags: tagsToUse,
      sig: data.sig,
    );
  }
  factory DataEvent.fromJson(Map<String, dynamic> data) {
    final tagsToUse = ((data['tags'] ?? []) as List<dynamic>)
        .map((t) => (t as List<dynamic>)
            .map((e) => SafeParser.parseString(e))
            .whereType<String>()
            .toList())
        .toList();
    final createdAtToUse = SafeParser.parseDateTime(data['createdAt']);
    final contentToUse = SafeParser.parseString(data['content']);
    final kindToUse = SafeParser.parseInt(data['kind']);
    final pubkeyToUse = SafeParser.parseString(data['pubkey']);
    var id = '';
    if (data['id'] != null) {
      id = data['id'];
    } else {
      id = NostrEvent.getEventId(
        kind: kindToUse ?? -1,
        content: contentToUse ?? '',
        createdAt: createdAtToUse,
        tags: tagsToUse,
        pubkey: pubkeyToUse ?? '',
      );
    }

    return DataEvent(
      id: id,
      pubkey: pubkeyToUse ?? '',
      kind: kindToUse,
      content: contentToUse,
      createdAt: createdAtToUse,
      tags: tagsToUse,
    );
  }

  String? getId() {
    if (kind != null && kind! >= 30000 && kind! < 40000) {
      // replaceable kind
      return getTagValue('d');
    }
    return id;
  }

  String? getTagValue(String tagName) {
    _genTagIndex();
    return tagIndex[tagName]?.elementAtOrNull(0)?.elementAtOrNull(1);
  }

  List<String>? getTagValues(String tagName) {
    _genTagIndex();
    return tagIndex[tagName]?.map((e) => e.elementAt(1)).toList();
  }

  List<String>? getMatchedTag(String tagName) {
    _genTagIndex();
    return tagIndex[tagName]?.elementAtOrNull(0)?.toList();
  }

  List<List<String>>? getMatchedTags(String tagName) {
    _genTagIndex();
    return tagIndex[tagName];
  }

  Map<String, List<List<String>>> _genTagIndex() {
    if (_tagIndex != null) {
      return tagIndex;
    }
    _tagIndex = {};
    tags?.forEach((e) {
      final key = e.elementAt(0);
      _tagIndex![key] ??= [];
      _tagIndex![key]!.add(e);
    });
    return tagIndex;
  }

  String generateEventId() {
    var eventId = NostrEvent.getEventId(
      kind: kind!,
      content: content ?? '',
      createdAt: createdAt ?? DateTime.timestamp(),
      tags: tags ?? [],
      pubkey: pubkey,
    );
    return eventId;
  }

  String toJson() {
    Map<String, dynamic> data = {};
    data['id'] = id;
    data['pubkey'] = pubkey;
    data['kind'] = kind;
    data['content'] = content;
    data['createdAt'] = createdAt?.millisecondsSinceEpoch;
    data['tags'] = tags;
    return jsonEncode(data);
  }

  Future<void> publish({
    int? difficulty,
    DataRelayList? relays,
    bool autoGenerateTags = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      tags ??= [];
      if (autoGenerateTags) {
        await generateContentTags();
      }
      NostrKeyPairs? keyPairs = await AppSecret.read();
      if (pubkey.isEmpty) {
        pubkey = keyPairs!.public;
      }
      createdAt = DateTime.timestamp();
      content ??= '';
      if (difficulty != null) {
        await minePow(this, difficulty);
      } else if (id?.isEmpty != false) {
        id = generateEventId();
      }
      if (sig?.isEmpty != false) {
        sig ??= keyPairs!.sign(id!);
      }
      if (!isVerified()) {
        throw Exception('event is not valid.');
      }
      final result =
          await NostrService.instance.relaysService.sendEventToRelaysAsync(
        this,
        timeout: timeout,
        relays: AppRelays.relays.clone().concat(relays).writeRelays,
      );
      print("publish: $result");
    } catch (err) {
      print('publish: ${toMap()}, ERROR: $err');
    }
  }

  // Future<void> generateTags() async {
  //       let tags = [];
  //   const g = await generateContentTags();
  //   const content = g.content;
  //   tags = g.tags;
  //   if (this.kind && this.isParamReplaceable()) {
  //     const dTag = this.getMatchingTags("d")[0];
  //     if (!dTag) {
  //       const title = this.tagValue("title");
  //       const randLength = title ? 6 : 16;
  //       let str = [...Array(randLength)].map(() => Math.random().toString(36)[2]).join("");
  //       if (title && title.length > 0) {
  //         str = title.replace(/[^a-z0-9]+/gi, "-").replace(/^-|-$/g, "") + "-" + str;
  //       }
  //       tags.push(["d", str]);
  //     }
  //   }
  //   if ((this.ndk?.clientName || this.ndk?.clientNip89) && !this.tagValue("client")) {
  //     const clientTag = ["client", this.ndk.clientName ?? ""];
  //     if (this.ndk.clientNip89)
  //       clientTag.push(this.ndk.clientNip89);
  //     tags.push(clientTag);
  //   }
  //   return { content: content || "", tags };
  // }

  addTagIfNew(List<String> t) {
    tags ??= [];
    bool isExists = tags!.any((t2) => t2[0] == t[0] && t2[1] == t[1]);
    if (!isExists) {
      tags!.add(t);
    }
  }

  addTag(String tag, String value, [String? marker, String? other]) {
    _tagIndex ??= {};
    _tagIndex![tag] ??= [];
    final tagValue = [
      tag,
      value,
      if (marker != null) ...["", marker],
      if (marker != null && other != null) other
    ];
    _tagIndex![tag]!.add(tagValue);
    addTagIfNew(tagValue);
  }

  addTagUser(String pubkey, [String? marker]) {
    addTag('e', pubkey, marker);
  }

  addTagEvent(String id, [String? marker, String? other]) {
    addTag('e', id, marker, other);
  }

  addTagReference(String id, [String? marker]) {
    addTag('a', id, marker);
  }

  Future<void> generateContentTags() async {
    var elements = await contentParser.parse(content!);
    for (var element in elements) {
      switch (element.matcherType) {
        case NostrLinkMatcher:
          final nostrUrl = element.text.startsWith(r'nostr:')
              ? element.text.replaceAll(r'nostr:', '')
              : element.text;
          if (nostrUrl.startsWith('npub')) {
            var data =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
            addTagUser(data, 'mention');
          } else if (nostrUrl.startsWith('nprofile')) {
            var data = NostrService.instance.utilsService
                .decodeNprofileToMap(nostrUrl)['pubkey'];
            addTagUser(data, 'mention');
          } else if (nostrUrl.startsWith('nevent')) {
            var data =
                NostrService.instance.utilsService.decodeNeventToMap(nostrUrl);
            addTagEvent(data['eventId'], 'mention', pubkey);
            if (data['pubkey'] != null) {
              addTagIfNew(["p", data['pubkey']]);
            }
          } else if (nostrUrl.startsWith('note')) {
            var id =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
            addTagEvent(id, 'mention', pubkey);
            addTagUser(pubkey);
          } else if (nostrUrl.startsWith('naddr')) {
            var hexdata =
                NostrService.instance.utilsService.decodeBech32(nostrUrl)[0];
            var data = Uint8List.fromList(hex.decode(hexdata));
            var tlvList = NostrService.instance.utilsService.tlv.decode(data);
            String? identifier;
            List<String>? relays = [];
            String? pubkey;
            int? kind;
            for (final tlv in tlvList) {
              if (tlv.type == 0) {
                identifier = ascii.decode(tlv.value);
              } else if (tlv.type == 1) {
                relays.add(ascii.decode(tlv.value));
              } else if (tlv.type == 2) {
                pubkey = hex.encode(tlv.value);
              } else if (tlv.type == 3) {
                kind = int.parse(hex.encode(tlv.value), radix: 16);
              }
            }
            var id = '$kind:$pubkey:$identifier';
            addTagReference(id, "mention");
            if (pubkey != null) {
              addTagUser(pubkey);
            }
          }
          continue;

        case HashTagMatcher:
          final hashtag = element.text.substring(1);
          addTag("t", hashtag.trim().toLowerCase());
          continue;

        case CustomEmojiMatcher:
          addTag("emoji", element.text);
          continue;
      }
    }
  }
}
