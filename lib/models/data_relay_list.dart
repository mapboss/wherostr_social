import 'dart:collection';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:wherostr_social/models/data_relay.dart';
import 'package:wherostr_social/services/nostr.dart';

class DataRelayList extends ListBase<DataRelay> {
  static DataRelayList failureList = DataRelayList(innerList: []);
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
  void add(DataRelay element) =>
      (innerList?.contains(element) ?? false) ? null : innerList?.add(element);

  @override
  void addAll(Iterable<DataRelay> iterable) => innerList?.addAll(iterable);

  List<String>? get all => innerList?.map((e) => e.url).toList();
  List<String>? get writeRelays =>
      innerList?.where((e) => e.marker != 'read').map((e) => e.url).toList();
  List<String>? get readRelays =>
      innerList?.where((e) => e.marker != 'write').map((e) => e.url).toList();

  factory DataRelayList.fromList(List<DataRelay>? relays) {
    return DataRelayList(innerList: relays);
  }
  factory DataRelayList.fromListString(List<String>? relays) {
    return DataRelayList(
        innerList: relays?.map((e) => DataRelay(url: e)).toList());
  }
  factory DataRelayList.fromTags(List<List<String>>? tags) {
    return DataRelayList(
        innerList: tags
            ?.where((e) => e.elementAtOrNull(0) == 'r')
            .map((e) => DataRelay.fromTag(e))
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
        String host = item.toString();
        if (list?.any((e) => e.toString() == host) == true) return;
        list?.add(item);
      });
    }
    return DataRelayList(innerList: list);
  }

  DataRelayList concatLeft(DataRelayList? relayList) {
    final list = relayList?.toList();
    if (innerList != null) {
      innerList?.forEach((item) {
        String host = item.toString();
        if (list?.any((e) => e.toString() == host) == true) return;
        list?.add(item);
      });
    }
    return DataRelayList(innerList: list);
  }

  DataRelayList combine(DataRelayList relayList, [bool removeError = true]) {
    innerList ??= [];
    final list = removeError
        ? innerList
            ?.where((e) => !NostrService
                .instance.relaysService.failureRelaysList
                .contains(e.url))
            .toList()
        : innerList?.toList();

    for (final item in relayList) {
      if (removeError &&
          NostrService.instance.relaysService.failureRelaysList
              .contains(item.url)) {
        continue;
      }
      if (list?.contains(item) == true) continue;
      list?.add(item);
    }
    return DataRelayList(innerList: list);
  }

  DataRelayList leftCombine(DataRelayList relayList,
      [bool removeError = true]) {
    final list = removeError
        ? relayList
            .where((e) => !NostrService.instance.relaysService.failureRelaysList
                .contains(e.url))
            .toList()
        : relayList.toList();
    innerList ??= [];
    innerList?.forEach((item) {
      if (removeError &&
          NostrService.instance.relaysService.failureRelaysList
              .contains(item.url)) {
        return;
      }
      if (list.contains(item) == true) return;
      list.add(item);
    });
    return DataRelayList(innerList: list);
  }

  @override
  String toString() {
    return innerList?.map((e) => e.toString()).join(', ') ?? '';
  }

  List<String> toListString() {
    return innerList?.map((e) => e.toString()).toList() ?? [];
  }
}
