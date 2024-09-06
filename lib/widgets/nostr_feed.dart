import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
import 'package:wherostr_social/utils/safe_parser.dart';
import 'package:wherostr_social/widgets/resize_observer.dart';

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
  Map<String, double> _heightMap = {};
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
  DateTime? _since;
  final _debouncer = Debouncer();
  final _throttler = Throttler();

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
                          return AnimatedSize(
                            key: ValueKey(item.id!),
                            curve: Curves.easeInOutCubic,
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                              height: _heightMap[item.id!],
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                primary: false,
                                child: ResizeObserver(
                                  onResized: (Size? oldSize, Size newSize) {
                                    if (_heightMap[item.id!] !=
                                        newSize.height) {
                                      _debouncer.debounce(
                                        duration:
                                            const Duration(milliseconds: 1000),
                                        onDebounce: () {
                                          setState(() {});
                                        },
                                      );
                                    }
                                    _heightMap[item.id!] = newSize.height;
                                  },
                                  child: widget.itemBuilder(context, item),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    AnimatedSize(
                      curve: Curves.easeInOutCubic,
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
                                    '${_newItems.length} new item${_newItems.length > 1 ? 's' : ''}'),
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
    unsubscribe().whenComplete(() {
      clearState();
      initialize();
    });
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NostrFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRelay = oldWidget.relays?.readRelays?.toString();
    final newRelay = widget.relays?.readRelays?.toString();
    if (oldWidget.authors?.length != widget.authors?.length ||
        oldWidget.t?.elementAtOrNull(0) != widget.t?.elementAtOrNull(0) ||
        oldWidget.isAscending != widget.isAscending ||
        oldRelay != newRelay) {
      unsubscribe().whenComplete(() {
        clearState();
        initialize();
      });
    }
    final muteList = context.read<AppStatesProvider>().me.muteList;
    if (_muteList.length != muteList.length) {
      _muteList = muteList.toList();
      final items = _allItems.where(filterEvent).toList();
      items.sort(sorting);
      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    }
  }

  Future<void> initialize() async {
    final muteList = context.read<AppStatesProvider>().me.muteList.toList();
    _muteList.addAll(muteList);
    subscribe();
  }

  bool replyFilter(DataEvent event) {
    return event.kind != 1 || (widget.includeReplies || !isReply(event: event));
  }

  bool muteFilter(DataEvent event) {
    return widget.includeMuted || !_muteList.contains(event.pubkey);
  }

  bool cutomFilter(DataEvent event) {
    return (widget.itemFilter?.call(event) ?? true);
  }

  bool filterEvent(DataEvent event) {
    return cutomFilter(event) && replyFilter(event) && muteFilter(event);
  }

  int sorting(DataEvent a, DataEvent b) {
    if (!widget.isAscending) {
      return b.createdAt!.compareTo(a.createdAt!);
    } else {
      return a.createdAt!.compareTo(b.createdAt!);
    }
  }

  void subscribe() {
    int hasMore = 0;
    const duration = Duration(milliseconds: 300);
    final Debouncer debouncer = Debouncer();
    final filter = NostrFilter(
      kinds: widget.kinds,
      authors: widget.authors,
      ids: widget.ids,
      limit: widget.limit,
      t: widget.t,
      a: widget.a,
      p: widget.p,
      e: widget.e,
      additionalFilters: widget.additionalFilters,
    );
    _newEventStream = NostrService.subscribe(
      [filter],
      relays: widget.relays,
      closeOnEnd: widget.disableSubscribe,
      onEose: (relay, ease) {
        if (!_initialized) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
          }
        }
        debouncer.debounce(
          duration: duration,
          onDebounce: () {
            _items.sort(sorting);
            if (mounted) {
              setState(() {});
            }
          },
        );
        _loading = false;
        _hasMore = hasMore >= (widget.limit / 2);
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _hasMore = hasMore >= widget.limit;
          });
        }
      },
    );

    _newEventListener = _newEventStream!.stream.listen(
      (event) {
        if (event.createdAt == null) return;
        final dataEvent = DataEvent.fromEvent(event);
        _allItems.add(dataEvent);
        if (_since == null || _since!.compareTo(dataEvent.createdAt!) >= 0) {
          _since ??= DateTime.now();
          hasMore += 1;
        }
        final isPass = filterEvent(dataEvent);
        if (!isPass) return;
        if (_since == null || _since!.compareTo(dataEvent.createdAt!) >= 0) {
          insertItem(dataEvent);
        } else {
          insertNewItem(dataEvent);
        }
      },
    );
  }

  void scrollToFirstItem() {
    _scrollController?.animateTo(_scrollController!.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);
  }

  void clearState() {
    setState(() {
      _heightMap = {};
      _since = null;
      _loading = true;
      _initialized = false;
      _hasMore = widget.isAscending ? false : true;
      _postItems.clear();
      _muteList.clear();
      _allItems.clear();
      _items.clear();
      _newItems.clear();
    });
  }

  Future<void> unsubscribe() async {
    try {
      await _newEventListener?.cancel();
      _newEventListener = null;

      _newEventStream?.close();
      _newEventStream = null;

      await _initEventListener?.cancel();
      _initEventListener = null;

      _initEventStream?.close();
      _initEventStream = null;
    } catch (err) {
      print('unsubscribe: $err');
    }
  }

  void insertItem(DataEvent event) {
    _items.add(event);
  }

  void insertNewItem(DataEvent event) {
    if (mounted) {
      setState(() {
        if (widget.isAscending == false) {
          _newItems.insert(0, event);
        } else {
          _newItems.add(event);
        }
      });
    }
    if (widget.autoRefresh) {
      _showNewItems();
    }
  }

  void fetchList([DataEvent? lastEvent]) {
    _loading = true;
    const duration = Duration(milliseconds: 500);
    final Debouncer debouncer = Debouncer();
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
      onEose: (relay, ease) {
        debouncer.debounce(
          duration: duration,
          onDebounce: () {
            if (mounted) {
              setState(() {});
            }
          },
        );
        _loading = false;
        _hasMore = hasMore >= (widget.limit / 2);
      },
      onEnd: () {
        setState(() {
          _hasMore = hasMore >= widget.limit;
        });
      },
    );
    _initEventListener = _initEventStream!.stream.listen(
      (event) {
        hasMore += 1;
        final dataEvent = DataEvent.fromEvent(event);
        _allItems.add(dataEvent);
        if (!filterEvent(dataEvent)) return;
        insertItem(dataEvent);
      },
    );
  }

  void _fetchMoreItems(DataEvent? e) async {
    if (_initialized != true || _loading == true) return;
    if (e == null) return;
    fetchList(e);
  }

  Future<void> _showNewItems() async {
    final newItems = _newItems.toList();
    newItems.sort(sorting);
    if (mounted) {
      setState(() {
        if (widget.isAscending == false) {
          _since = DateTime.now();
          _items.insertAll(0, newItems);
        } else {
          _since = DateTime.now();
          _items.addAll(newItems);
        }
        _newItems.clear();
      });
    }
  }

  bool _handleNotification(ScrollNotification scrollNotification) {
    if (_loading ||
        widget.isAscending ||
        !_hasMore ||
        !scrollNotification.metrics.atEdge) {
      return false;
    }
    if ((widget.reverse == false && scrollNotification.metrics.pixels > 0) ||
        (widget.reverse == true && scrollNotification.metrics.pixels == 0)) {
      _throttler.throttle(
          duration: const Duration(milliseconds: 1000),
          onThrottle: () {
            _allItems.sort(sorting);
            _fetchMoreItems(_allItems.last);
          });
      return true;
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
      eoseRatio: 1.2,
      timeout: const Duration(seconds: 3),
      relays: widget.relays,
    );
  }
}
