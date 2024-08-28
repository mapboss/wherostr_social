import 'dart:collection';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_relay.dart';

class DataRelayList extends ListBase<DataRelay> {
  List<DataRelay>? innerList;

  DataRelayList({this.innerList});

  @override
  int get length => innerList?.length ?? 0;

  @override
  set length(int length) {
    innerList?.length = length;
  }

  @override
  void operator []=(int index, DataRelay value) {
    innerList![index] = value;
  }

  @override
  DataRelay operator [](int index) => innerList![index];

  @override
  void add(DataRelay element) => innerList?.add(element);

  @override
  void addAll(Iterable<DataRelay> iterable) => innerList?.addAll(iterable);

  List<String>? get all => innerList?.map((e) => e.url).toList();
  List<String>? get writeRelays =>
      innerList?.where((e) => e.marker != 'read').map((e) => e.url).toList();
  List<String>? get readRelays =>
      innerList?.where((e) => e.marker != 'write').map((e) => e.url).toList();

  factory DataRelayList.fromList(List<DataRelay>? relays) {
    return DataRelayList(innerList: relays!);
  }
  factory DataRelayList.fromListString(List<String>? relays) {
    return DataRelayList(
        innerList: relays?.map((e) => DataRelay(url: e)).toList());
  }
  factory DataRelayList.fromTags(List<List<String>>? tags) {
    return DataRelayList(
        innerList: tags
            ?.where((e) => e.elementAtOrNull(0) == 'r')
            .map((e) =>
                DataRelay(url: e.elementAt(1), marker: e.elementAtOrNull(2)))
            .toList());
  }
  factory DataRelayList.fromEvent(NostrEvent? event) {
    return DataRelayList.fromTags(event?.tags);
  }

  List<List<String>> toTags() {
    return innerList
            ?.map((e) => ['r', e.url, if (e.marker != null) e.marker!])
            .toList() ??
        [];
  }

  DataRelayList clone() {
    return DataRelayList.fromList(
        innerList?.whereType<DataRelay>().map((e) => e.clone()).toList());
  }

  DataRelayList concat(DataRelayList? relayList) {
    final list = innerList?.toList();
    if (relayList?.innerList != null) {
      relayList?.innerList?.forEach((item) {
        if (list?.any((e) => e.url == item.url) == true) return;
        list?.add(item);
      });
    }
    return DataRelayList(innerList: list);
  }

  @override
  String toString() {
    return innerList?.map((e) => e.url).join(', ') ?? '';
  }
}
