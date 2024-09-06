import 'dart:convert';
import 'dart:typed_data';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/tlv.dart';
import 'package:wherostr_social/services/nostr.dart';

bool isReply({
  required NostrEvent event,
  String? referenceEventId,
  bool isDirectOnly = false,
}) {
  if (event.tags == null) {
    return false;
  }
  try {
    Iterable<List<String>> eTags =
        event.tags!.where((tag) => tag.firstOrNull == 'e');
    Iterable<List<String>> aTags =
        event.tags!.where((tag) => tag.firstOrNull == 'a');

    bool isReply =
        eTags.where((tag) => tag.elementAtOrNull(3) != 'mention').firstOrNull !=
            null;
    isReply = isReply ||
        aTags.where((tag) => tag.elementAtOrNull(3) != 'mention').firstOrNull !=
            null;

    bool isDirect = false;
    if (isReply && isDirectOnly && referenceEventId != null) {
      if ((eTags
                      .where((tag) =>
                          tag.elementAtOrNull(1) == referenceEventId &&
                          tag.elementAtOrNull(3) == 'root')
                      .firstOrNull !=
                  null &&
              eTags
                      .where((tag) => tag.elementAtOrNull(3) == 'reply')
                      .firstOrNull ==
                  null) ||
          eTags
                  .where((tag) =>
                      tag.elementAtOrNull(1) == referenceEventId &&
                      tag.elementAtOrNull(3) == 'reply')
                  .firstOrNull !=
              null ||
          ((eTags.lastOrNull?.elementAtOrNull(3) ?? '') == '' &&
              eTags.lastOrNull?.elementAtOrNull(1) == referenceEventId)) {
        isDirect = true;
      }
    }
    return event.kind == 1 && isReply && (!isDirectOnly || isDirect);
  } catch (error) {}
  return false;
}

String? getParentEventId({
  required NostrEvent event,
}) {
  if (event.tags == null) {
    return null;
  }
  try {
    Iterable<List<String>> eTags =
        event.tags!.where((tag) => tag.firstOrNull == 'e');
    return eTags
            .where((tag) => tag.elementAtOrNull(3) == 'reply')
            .lastOrNull
            ?.elementAtOrNull(1) ??
        eTags
            .where((tag) => tag.elementAtOrNull(3) == 'root')
            .lastOrNull
            ?.elementAtOrNull(1);
  } catch (error) {}
  return null;
}

String getNostrAddress(NostrEvent event) {
  final dTag = event.tags
      ?.where((item) => item.firstOrNull == 'd')
      .firstOrNull
      ?.elementAtOrNull(1);
  return NostrService.instance.utilsService.encodeBech32(
      hex.encode(NostrService.instance.utilsService.tlv.encode([
        ...(dTag == null
            ? []
            : [
                TLV(
                  type: 0,
                  length: 32,
                  value: ascii.encode(dTag),
                ),
              ]),
        TLV(
          type: 2,
          length: 32,
          value: Uint8List.fromList(hex.decode(event.pubkey)),
        ),
        TLV(
          type: 3,
          length: 32,
          value: Uint8List.fromList(integerToUint8Array(event.kind!)),
        ),
      ])),
      'naddr');
}

bool isMention(NostrEvent event, String pubkey) {
  return event.content?.contains(
          NostrService.instance.utilsService.encodeNProfile(pubkey: pubkey)) ??
      false;
}

String? getReferencedEventId(NostrEvent event) {
  switch (event.kind) {
    case 1:
      final eTags = event.tags?.where((item) => item.firstOrNull == 'e');
      return (eTags
                  ?.where((item) => item.elementAtOrNull(3) == 'reply')
                  .lastOrNull ??
              eTags
                  ?.where((item) => item.elementAtOrNull(3) == 'root')
                  .lastOrNull)
          ?.elementAtOrNull(1);
    case 6:
    case 7:
    case 9735:
      return event.tags!
          .where((tag) => tag.firstOrNull == 'e')
          .lastOrNull
          ?.elementAtOrNull(1);
    default:
      return null;
  }
}

String? getEmojiUrl({
  required NostrEvent event,
  required String emoji,
}) {
  String? emojiName = event.content?.replaceAll(':', '');
  return emojiName == null
      ? null
      : event.tags!
          .where((tag) =>
              tag.firstOrNull == 'emoji' && tag.elementAtOrNull(1) == emojiName)
          .firstOrNull
          ?.elementAtOrNull(2);
}

String? getZappee({
  required NostrEvent event,
}) {
  Iterable<List<String>> descriptionTags =
      event.tags!.where((tag) => tag.firstOrNull == 'description');
  String? descriptionJson = descriptionTags.firstOrNull?.elementAtOrNull(1);
  if (descriptionJson != null) {
    final description = jsonDecode(descriptionJson) as Map<String, dynamic>;
    return description['pubkey'];
  }
  return null;
}

double? getZapAmount({
  required NostrEvent event,
}) {
  String? bolt11 = event.tags!
      .where((tag) => tag.firstOrNull == 'bolt11')
      .firstOrNull
      ?.elementAtOrNull(1);
  return bolt11 == null
      ? null
      : Bolt11PaymentRequest(bolt11).amount.toDouble() * 100000000;
}

Uint8List integerToUint8Array(int number) {
  final uint8Array = Uint8List(4);
  uint8Array[0] = (number >> 24) & 255;
  uint8Array[1] = (number >> 16) & 255;
  uint8Array[2] = (number >> 8) & 255;
  uint8Array[3] = number & 255;
  return uint8Array;
}
