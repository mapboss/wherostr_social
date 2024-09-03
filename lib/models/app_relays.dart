import 'package:get_storage/get_storage.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

final defaultRelays = DataRelayList.fromTags([
  ['r', 'wss://nos.lol', 'read'],
  ['r', 'wss://nostr.wine', 'read'],
  ['r', 'wss://relay.damus.io'],
  ['r', 'wss://relay.primal.net'],
  ['r', 'wss://relay.nostr.band'],
]);

class AppRelays {
  static DataRelayList defaults = defaultRelays.clone();
  static DataRelayList? _relays;
  static DataRelayList get relays => _relays ?? defaultRelays.clone();

  static Future<void> init() async {
    try {
      var storage = GetStorage('app');
      print('storage: ${storage.hasData('app_relays')}');
      if (storage.hasData('app_relays')) {
        final appRelays = storage.read<List<dynamic>>('app_relays');
        print('appRelays: $appRelays');
        try {
          _relays = DataRelayList.fromListString(storage
              .read<List<dynamic>>('app_relays')
              ?.map((e) => SafeParser.parseString(e) ?? "")
              .toList());
        } catch (err) {
          final tags = storage
              .read<List<dynamic>>('app_relays')
              ?.map((e) => (e as List<dynamic>)
                  .map((j) => SafeParser.parseString(j) ?? "")
                  .toList())
              .toList();
          if (tags != null) {
            _relays = DataRelayList.fromTags(tags);
          }
        }
      }
    } catch (err) {
      print('AppRelays.init: $err');
    }
  }

  static Future<void> setRelays(DataRelayList? appRelays) async {
    try {
      print('appRelays: $appRelays');
      var storage = GetStorage('app');
      await storage.write('app_relays', appRelays?.toTags());
      _relays = appRelays;
    } catch (err) {
      print('AppRelays.setRelays: $err');
    }
  }

  static Future<void> resetRelays() async {
    try {
      var storage = GetStorage('app');
      await storage.remove('app_relays');
      _relays = null;
    } catch (err) {
      print('AppRelays.resetRelays: $err');
    }
  }
}
