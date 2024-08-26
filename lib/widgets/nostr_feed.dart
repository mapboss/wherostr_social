import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/utils/safe_parser.dart';

class NostrFeed extends StatefulWidget {
  final Widget Function(BuildContext context, DataEvent event) itemBuilder;
  final List<int> kinds;
  final DataRelayList? relays;
  final List<String>? authors;
  final List<String>? t;
  final List<String>? a;
  final List<String>? p;
  final List<String>? e;
  final Map<String, dynamic>? additionalFilters;
  final int limit;
  final bool Function(DataEvent event)? itemFilter;
  final bool reverse;
  final bool isAscending;
  final bool autoRefresh;
  final bool includeReplies;
  final bool includeMuted;
  final ScrollController? scrollController;
  final Color? backgroundColor;

  const NostrFeed({
    super.key,
    required this.itemBuilder,
    required this.kinds,
    this.relays,
    this.t,
    this.a,
    this.p,
    this.e,
    this.authors,
    this.additionalFilters,
    this.limit = 30,
    this.itemFilter,
    this.reverse = false,
    this.isAscending = false,
    this.autoRefresh = false,
    this.includeReplies = false,
    this.includeMuted = false,
    this.scrollController,
    this.backgroundColor,
  });
  @override
  State createState() => NostrFeedState();
}

class NostrFeedState extends State<NostrFeed> {
  NostrEventsStream? _newEventStream;
  StreamSubscription? _newEventListener;
  bool _initialized = false;
  bool _loading = false;
  bool _hasMore = true;
  final List<DataEvent> _allItems = [];
  final List<DataEvent> _newItems = [];
  final Map<String, Widget> _postItems = {};
  List<String> _muteList = [];
  List<DataEvent> _items = [];
  ScrollController? _scrollController;

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Container(
      color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,
      child: !_initialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading'),
                ],
              ),
            )
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No items'),
                    ],
                  ),
                )
              : Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: [
                    NotificationListener(
                      onNotification: _handleNotification,
                      child: ListView.builder(
                        controller: widget.scrollController == null
                            ? _scrollController
                            : null,
                        reverse: widget.reverse,
                        itemCount: _hasMore ? _items.length + 1 : _items.length,
                        itemBuilder: (context, index) {
                          if (_items.length == index) {
                            return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(),
                                  ),
                                ));
                          }
                          final item = _items[index];
                          if (!_postItems.containsKey(item.id!)) {
                            _postItems[item.id!] = AnimatedSize(
                              key: Key(item.id!),
                              curve: Curves.easeIn,
                              duration: const Duration(milliseconds: 300),
                              child: widget.itemBuilder(context, item),
                            );
                          }
                          return _postItems[item.id!];
                        },
                      ),
                    ),
                    AnimatedSize(
                      curve: Curves.easeIn,
                      duration: const Duration(milliseconds: 300),
                      child: !widget.autoRefresh && _newItems.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      themeData.colorScheme.secondary,
                                ),
                                onPressed: () {
                                  _showNewItems();
                                  scrollToFirstItem();
                                },
                                child: Text(
                                    '${_newItems.length} new item${_newItems.isNotEmpty ? 's' : ''}'),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _scrollController = widget.scrollController ?? ScrollController();
    });
    initialize();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NostrFeed oldWidget) {
    final oldRelay = oldWidget.relays?.readRelays?.toString();
    final newRelay = widget.relays?.readRelays?.toString();
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authors?.length != widget.authors?.length ||
        oldWidget.t?[0] != widget.t?[0] ||
        oldWidget.isAscending != widget.isAscending ||
        oldRelay != newRelay) {
      unsubscribe().whenComplete(() {
        clearState();
        initialize();
      });
    }
    final muteList = context.read<AppStatesProvider>().me.muteList;
    if (_muteList.length != muteList.length) {
      setState(() {
        _muteList = muteList.toList();
        _items = _allItems.where(filterEvent).toList();
      });
    }
  }

  bool filterEvent(DataEvent event) {
    return widget.itemFilter?.call(event) != false &&
        (widget.includeReplies || !isReply(event: event)) &&
        (widget.includeMuted || _muteList.contains(event.pubkey) != true);
  }

  void subscribe(DateTime since) async {
    print('subscribe.authors: ${widget.authors?.length}');
    _newEventStream = NostrService.subscribe([
      NostrFilter(
        since: since,
        kinds: widget.kinds,
        authors: widget.authors,
        t: widget.t,
        a: widget.a,
        p: widget.p,
        e: widget.e,
        additionalFilters: widget.additionalFilters,
      )
    ], relays: widget.relays);
    _newEventListener = _newEventStream!.stream.listen((event) {
      insertNewItem(DataEvent.fromEvent(event));
    });
  }

  void scrollToFirstItem() {
    _scrollController?.animateTo(_scrollController!.position.minScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void clearState() {
    if (mounted) {
      setState(() {
        _initialized = false;
        _loading = true;
        _hasMore = true;
        _postItems.clear();
        _muteList.clear();
        _allItems.clear();
        _items.clear();
        _newItems.clear();
      });
    }
  }

  Future<void> unsubscribe() async {
    try {
      if (_newEventListener != null) {
        await _newEventListener!.cancel();
        _newEventListener = null;
      }
      if (_newEventStream != null) {
        _newEventStream!.close();
        _newEventStream = null;
      }
    } catch (err) {
      print('unsubscribe: $err');
    }
  }

  void insertNewItem(DataEvent event) {
    _allItems.insert(0, event);
    if (!filterEvent(event)) return;
    print('insertNewItem: ${event.id}');
    setState(() {
      if (widget.isAscending == false) {
        _newItems.insert(0, event);
      } else {
        _newItems.add(event);
      }
    });
    if (widget.autoRefresh) {
      _showNewItems();
    }
  }

  Future<void> initialize() async {
    final muteList = context.read<AppStatesProvider>().me.muteList.toList();
    _muteList.addAll(muteList);

    DateTime until = DateTime.timestamp().add(const Duration(days: 1));
    NostrFilter filter = NostrFilter(
      limit: 50,
      until: until,
      kinds: widget.kinds,
      authors: widget.authors,
      t: widget.t,
      a: widget.a,
      p: widget.p,
      e: widget.e,
      additionalFilters: widget.additionalFilters,
    );
    List<DataEvent> newItems = await NostrService.fetchEvents(
      [filter],
      eoseRatio: 1,
      isAscending: widget.isAscending,
      relays: widget.relays,
    );

    if (newItems.isNotEmpty) {
      await Future.wait([
        _fetchUsersFromEvents(newItems),
        _fetchRelatedEventsFromEvents(newItems)
      ]);
    }

    subscribe(DateTime.timestamp());
    setState(() {
      _initialized = true;
      _loading = false;
      if (newItems.isNotEmpty) {
        _allItems.addAll(newItems);
        _items = _allItems.where(filterEvent).toList();
        if (_items.length < 30) {
          if (widget.isAscending && !widget.reverse) {
            _hasMore = false;
          } else if (widget.reverse == false) {
            _fetchMoreItems(_items.last);
          } else if (widget.reverse) {
            _fetchMoreItems(_items.first);
          }
        }
      } else {
        _hasMore = false;
      }
    });
  }

  void _fetchMoreItems(DataEvent? e) async {
    if (_initialized != true || _loading == true) return;
    if (e == null) return;
    setState(() {
      _loading = true;
    });
    DateTime? until;
    DateTime? since;
    until = e.createdAt!.subtract(const Duration(milliseconds: 10));
    NostrFilter filter = NostrFilter(
      limit: 50,
      until: until,
      since: since,
      kinds: widget.kinds,
      authors: widget.authors,
      t: widget.t,
      a: widget.a,
      p: widget.p,
      e: widget.e,
      additionalFilters: widget.additionalFilters,
    );
    List<DataEvent> newItems = await NostrService.fetchEvents(
      [filter],
      eoseRatio: 1,
      isAscending: widget.isAscending,
      relays: widget.relays,
    );
    if (newItems.isNotEmpty) {
      await Future.wait([
        _fetchUsersFromEvents(newItems),
        _fetchRelatedEventsFromEvents(newItems)
      ]);
    }
    setState(() {
      _loading = false;
      if (newItems.isNotEmpty) {
        _allItems.addAll(newItems);
      }
      newItems = newItems.where(filterEvent).toList();
      _hasMore = newItems.isNotEmpty;
      if (newItems.isNotEmpty) {
        _items.addAll(newItems);
      }
    });
  }

  Future<void> _showNewItems() async {
    var future = _fetchUsersFromEvents(_newItems);
    if (widget.isAscending == false) {
      _allItems.insertAll(0, _newItems);
      _items.insertAll(0, _newItems);
    } else {
      _allItems.addAll(_newItems);
      _items.addAll(_newItems);
    }
    var items = _items;
    setState(() {
      _newItems.clear();
    });
    await future;
    setState(() {
      _items = items;
    });
  }

  bool _handleNotification(ScrollNotification scrollNotification) {
    if (_hasMore &&
        scrollNotification.metrics.pixels > 0 &&
        scrollNotification.metrics.atEdge) {
      if (widget.reverse == false) {
        _fetchMoreItems(_items.last);
      } else {
        _fetchMoreItems(_items.first);
      }
    }
    return false;
  }

  Future<void> _fetchUsersFromEvents(List<DataEvent> events) async {
    Set<String> pubkeySet = <String>{};
    for (var e in events) {
      pubkeySet.add(e.pubkey);
      e.tags?.where((t) => t.firstOrNull == 'p').forEach((t) {
        pubkeySet.add(t[1]);
      });
      if (e.kind == 6) {
        try {
          if (e.content == null) continue;
          var eventJson = jsonDecode(e.content!);
          pubkeySet.add(eventJson['pubkey']);
          ((eventJson['tags'] ?? []) as List<dynamic>)
              .where((t) => ((t ?? []) as List<dynamic>).firstOrNull == 'p')
              .forEach((t) {
            var val = SafeParser.parseString(t[1]);
            if (val != null) {
              pubkeySet.add(val);
            }
          });
        } catch (err) {
          print('_fetchUsersFromEvents: ERROR: $err');
        }
      }
    }
    print(
        '_fetchUsersFromEvents: events: ${events.length}, pubkey: ${pubkeySet.length}');
    if (pubkeySet.isEmpty) return;
    await NostrService.fetchUsers(
      pubkeySet.toList(),
      timeout: const Duration(seconds: 3),
      relays: widget.relays,
    );
  }

  Future<void> _fetchRelatedEventsFromEvents(List<DataEvent> events) async {
    Set<String> idSet = <String>{};
    for (var e in events) {
      if (e.kind == 1) {
        e.tags
            ?.where((t) => t.firstOrNull == 'e' || t.firstOrNull == 'a')
            .forEach((t) {
          var value = t.elementAt(1);
          idSet.add(value);
        });
      } else if (e.kind == 6) {
        try {
          if (e.content == null) continue;
          var eventJson = jsonDecode(e.content!);
          idSet.add(eventJson['pubkey']);
          ((eventJson['tags'] ?? []) as List<dynamic>).where((t) {
            var item = ((t ?? []) as List<dynamic>);
            return item.firstOrNull == 'p' || item.firstOrNull == 'a';
          }).forEach((t) {
            var val = SafeParser.parseString(t[1]);
            if (val != null) {
              idSet.add(val);
            }
          });
        } catch (err) {
          print('_fetchRelatedEventsFromEvents: $err');
        }
      }
    }
    print(
        '_fetchRelatedEventsFromEvents: events: ${events.length}, id: ${idSet.length}');
    if (idSet.isEmpty) return;
    await NostrService.fetchEventIds(
      idSet.toList(),
      eoseRatio: 1,
      timeout: const Duration(seconds: 3),
      relays: widget.relays,
    );
  }
}
