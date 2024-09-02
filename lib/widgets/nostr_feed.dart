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
  final List<String>? ids;
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
  final bool disableSubscribe;
  final ScrollController? scrollController;
  final Color? backgroundColor;

  const NostrFeed({
    super.key,
    required this.itemBuilder,
    required this.kinds,
    this.relays,
    this.authors,
    this.ids,
    this.t,
    this.a,
    this.p,
    this.e,
    this.additionalFilters,
    this.limit = 30,
    this.itemFilter,
    this.reverse = false,
    this.isAscending = false,
    this.autoRefresh = false,
    this.includeReplies = false,
    this.includeMuted = false,
    this.disableSubscribe = false,
    this.scrollController,
    this.backgroundColor,
  });
  @override
  State createState() => NostrFeedState();
}

class NostrFeedState extends State<NostrFeed> {
  NostrEventsStream? _newEventStream;
  StreamSubscription<NostrEvent>? _newEventListener;
  NostrEventsStream? _initEventStream;
  StreamSubscription<NostrEvent>? _initEventListener;
  bool _initialized = false;
  bool _loading = true;
  bool _hasMore = false;
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
                        itemCount: !widget.isAscending && _hasMore
                            ? _items.length + 1
                            : _items.length,
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
    clearState();
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
        if (mounted) {
          clearState();
          initialize();
        }
      });
    }
    final muteList = context.read<AppStatesProvider>().me.muteList;
    if (_muteList.length != muteList.length) {
      if (mounted) {
        setState(() {
          _muteList = muteList.toList();
          _items = _allItems.where(filterEvent).toList();
        });
      }
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
        ids: widget.ids,
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
    _initialized = false;
    _hasMore = widget.isAscending ? false : true;
    _postItems.clear();
    _muteList.clear();
    _allItems.clear();
    _items.clear();
    _newItems.clear();
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
      if (_initEventListener != null) {
        await _initEventListener!.cancel();
        _initEventListener = null;
      }
      if (_initEventStream != null) {
        _initEventStream!.close();
        _initEventStream = null;
      }
    } catch (err) {
      print('unsubscribe: $err');
    }
  }

  void insertNewItem(DataEvent event) {
    _allItems.insert(0, event);
    if (!filterEvent(event)) return;
    print('insertNewItem: ${event.id}');
    if (mounted) {
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
  }

  Future<void> fetchList([DataEvent? lastEvent]) async {
    bool isInitializeState = lastEvent == null;
    Completer completer = Completer();
    setState(() {
      _loading = true;
    });
    DateTime? until;
    DateTime? since;
    if (!widget.isAscending) {
      until = lastEvent == null
          ? DateTime.now()
          : lastEvent.createdAt?.subtract(const Duration(milliseconds: 10));
    }
    NostrFilter filter = NostrFilter(
      until: until,
      since: since,
      limit: widget.limit,
      kinds: widget.kinds,
      authors: widget.authors,
      ids: widget.ids,
      t: widget.t,
      a: widget.a,
      p: widget.p,
      e: widget.e,
      additionalFilters: widget.additionalFilters,
    );
    int hasMore = 0;
    _initEventStream = NostrService.subscribe(
      [filter],
      relays: widget.relays,
      closeOnEnd: true,
      onEnd: (subscriptionId) {
        if (isInitializeState && !widget.disableSubscribe) {
          subscribe(DateTime.now());
        }
        setState(() {
          if (isInitializeState) {
            _initialized = true;
          }
          _loading = false;
          _hasMore = hasMore >= widget.limit;
        });
        // if (!widget.isAscending && _hasMore) {
        //   _fetchMoreItems(_allItems.last);
        // }
      },
    );
    _initEventListener = _initEventStream!.stream.listen(
      (event) {
        hasMore += 1;
        final dataEvent = DataEvent.fromEvent(event);
        if (!filterEvent(dataEvent)) return;
        _allItems.add(dataEvent);
        if (!widget.isAscending) {
          _allItems.sort(((a, b) => b.createdAt!.compareTo(a.createdAt!)));
        } else {
          _allItems.sort(((a, b) => a.createdAt!.compareTo(b.createdAt!)));
        }
        if (mounted) {
          setState(() {
            _items = _allItems.toList();
          });
        }

        if (!completer.isCompleted) {
          if (isInitializeState) {
            setState(() {
              _loading = false;
              _initialized = true;
            });
          }
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  Future<void> initialize() async {
    final muteList = context.read<AppStatesProvider>().me.muteList.toList();
    if (mounted) {
      setState(() {
        _muteList.addAll(muteList);
      });
    }
    await fetchList();
  }

  void _fetchMoreItems(DataEvent? e) async {
    if (_initialized != true || _loading == true) return;
    if (e == null) return;
    fetchList(e);
  }

  Future<void> _showNewItems() async {
    // var future = _fetchUsersFromEvents(_newItems);
    if (widget.isAscending == false) {
      _allItems.insertAll(0, _newItems);
      _items.insertAll(0, _newItems);
    } else {
      _allItems.addAll(_newItems);
      _items.addAll(_newItems);
    }
    var items = _items;
    if (mounted) {
      setState(() {
        _newItems.clear();
        _items = items;
      });
    }
  }

  bool _handleNotification(ScrollNotification scrollNotification) {
    if (!widget.isAscending &&
        _hasMore &&
        widget.reverse == false &&
        scrollNotification.metrics.pixels > 0 &&
        scrollNotification.metrics.atEdge) {
      _fetchMoreItems(_items.last);
    } else if (!widget.isAscending &&
        _hasMore &&
        widget.reverse == true &&
        scrollNotification.metrics.pixels == 0 &&
        scrollNotification.metrics.atEdge) {
      _fetchMoreItems(_items.first);
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
