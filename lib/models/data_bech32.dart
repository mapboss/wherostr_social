import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_nostr/nostr/model/tlv.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';

class DataBech32 {
  String? identifier;
  String? pubkey;
  String? eventId;
  int? kind;
  List<String>? relays;

  DataBech32(
      {this.pubkey, this.identifier, this.eventId, this.kind, this.relays});

  factory DataBech32.fromString(String nevent) {
    var hexdata = NostrService.instance.utilsService.decodeBech32(nevent)[0];
    var data = Uint8List.fromList(hex.decode(hexdata));
    var tlvList = NostrService.instance.utilsService.tlv.decode(data);
    String? eventId;
    String? identifier;
    String? pubkey;
    int? kind;
    List<String> relays = [];
    for (final tlv in tlvList) {
      if (tlv.type == 0) {
        try {
          identifier = ascii.decode(tlv.value);
        } catch (err) {
          eventId = hex.encode(tlv.value);
        }
      } else if (tlv.type == 1) {
        relays.add(ascii.decode(tlv.value));
      } else if (tlv.type == 2) {
        pubkey = hex.encode(tlv.value);
      } else if (tlv.type == 3) {
        kind = int.parse(hex.encode(tlv.value), radix: 16);
      }
    }
    return DataBech32(
      eventId: eventId,
      identifier: identifier,
      kind: kind,
      pubkey: pubkey,
      relays: relays,
    );
  }

  String getId() {
    if (kind != null && kind! >= 30000 && kind! < 40000) {
      return '$kind:$pubkey:$identifier';
    }
    return eventId!;
  }

  String toNAddress() {
    return NostrService.instance.utilsService.encodeBech32(
        hex.encode(NostrService.instance.utilsService.tlv.encode([
          ...(identifier == null
              ? []
              : [
                  TLV(
                    type: 0,
                    length: 32,
                    value: ascii.encode(identifier!),
                  ),
                ]),
          TLV(
            type: 2,
            length: 32,
            value: Uint8List.fromList(hex.decode(pubkey!)),
          ),
          TLV(
            type: 3,
            length: 32,
            value: Uint8List.fromList(integerToUint8Array(kind!)),
          ),
        ])),
        'naddr');
  }

  String toNEvent() {
    return NostrService.instance.utilsService.encodeBech32(
        hex.encode(NostrService.instance.utilsService.tlv.encode([
          ...(identifier == null
              ? []
              : [
                  TLV(
                    type: 0,
                    length: 32,
                    value: ascii.encode(identifier!),
                  ),
                ]),
          TLV(
            type: 2,
            length: 32,
            value: Uint8List.fromList(hex.decode(pubkey!)),
          ),
          TLV(
            type: 3,
            length: 32,
            value: Uint8List.fromList(integerToUint8Array(kind!)),
          ),
        ])),
        'nevent');
  }
}
