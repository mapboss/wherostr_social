import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/relay_informations.dart';
import 'package:wherostr_social/services/nostr.dart';

class DataRelay {
  final String url;
  String? marker;
  DataRelay({
    required this.url,
    this.marker,
  });

  factory DataRelay.fromTag(List<String> tagItem) {
    return DataRelay(
        url: tagItem.elementAt(1), marker: tagItem.elementAtOrNull(2));
  }

  List<String> toTag() {
    return ['r', url, if (marker != null) marker!];
  }

  Future<RelayInformations?> getRelayInformation([Nostr? instance]) {
    instance ??= NostrService.instance;
    return instance.relaysService.relayInformationsDocumentNip11(relayUrl: url);
  }

  DataRelay clone() {
    return DataRelay(url: url, marker: marker);
  }

  @override
  String toString() {
    return url;
  }
}
