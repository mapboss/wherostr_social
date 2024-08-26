import 'package:wherostr_social/models/data_relay.dart';

class DataRelayList {
  List<DataRelay>? items;
  List<String>? get all => items?.map((e) => e.url).toList();
  List<String>? get writeRelays =>
      items?.where((e) => e.marker != 'read').map((e) => e.url).toList();
  List<String>? get readRelays =>
      items?.where((e) => e.marker != 'write').map((e) => e.url).toList();

  DataRelayList({
    this.items = const [],
  });

  factory DataRelayList.fromList(List<DataRelay>? relays) {
    return DataRelayList(items: relays);
  }
  factory DataRelayList.fromListString(List<String>? relays) {
    return DataRelayList(items: relays?.map((e) => DataRelay(url: e)).toList());
  }
  factory DataRelayList.fromTags(List<List<String>>? tags) {
    return DataRelayList(
        items: tags
            ?.where((e) => e.elementAtOrNull(0) == 'r')
            .map((e) =>
                DataRelay(url: e.elementAt(1), marker: e.elementAtOrNull(2)))
            .toList());
  }

  List<List<String>> toTags() {
    return items
            ?.map((e) => ['r', e.url, if (e.marker != null) e.marker!])
            .toList() ??
        [];
  }

  DataRelayList clone() {
    return DataRelayList.fromList(items?.map((e) => e.clone()).toList());
  }

  void add(DataRelay value) {
    items ??= [];
    items?.add(value);
  }

  bool remove(DataRelay? value) {
    items ??= [];
    return items!.remove(value);
  }

  bool contains(DataRelay? value) {
    items ??= [];
    return items!.contains(value);
  }

  int indexWhere(bool Function(DataRelay) test, [int start = 0]) {
    items ??= [];
    return items!.indexWhere(test, start);
  }

  void removeWhere(bool Function(DataRelay) test) {
    items ??= [];
    items!.removeWhere(test);
  }

  void sort([int Function(DataRelay, DataRelay)? compare]) {
    items ??= [];
    items?.sort(compare);
  }

  DataRelayList concat(DataRelayList? relayList) {
    final list = items?.toList();
    if (relayList?.items != null) {
      relayList?.items?.forEach((item) {
        if (list?.any((e) => e.url == item.url) == true) return;
        list?.add(item);
      });
    }
    return DataRelayList(items: list);
  }

  List<DataRelay>? toList() {
    return items?.toList();
  }

  @override
  String toString() {
    return items?.map((e) => e.url).join(', ') ?? '';
  }
}
