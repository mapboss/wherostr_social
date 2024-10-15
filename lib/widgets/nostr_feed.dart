import 'dart:async';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_states.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/models/data_relay_list.dart';
import 'package:wherostr_social/services/nostr.dart';
import 'package:wherostr_social/utils/nostr_event.dart';
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
  final int Function(DataEvent a, DataEvent b)? itemSorting;
  final bool Function(DataEvent event)? itemFilter;
  final FutureOr<DataEvent> Function(DataEvent event)? itemMapper;
  final bool reverse;
  final bool isAscending;
  final bool autoRefresh;
  final bool includeReplies;
  final bool includeMuted;
  final bool disableSubscribe;
  final bool disableLimit;
  final bool isDynamicHeight;
  final ScrollController? scrollController;
  final Axis scrollDirection;
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
    this.itemSorting,
    this.itemFilter,
    this.itemMapper,
    this.reverse = false,
    this.isAscending = false,
    this.autoRefresh = false,
    this.includeReplies = false,
    this.includeMuted = false,
    this.disableLimit = false,
    this.disableSubscribe = false,
    this.isDynamicHeight = false,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
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
  final int _limitRequest = 60;
  final int _limitDisplay = 30;
  final List<DataEvent> _allItems = [];
  final List<DataEvent> _newItems = [];
  final Map<String, Widget> _postItems = {};
  List<String> _muteList = [];
  List<DataEvent> _items = [];
  ScrollController? _scrollController;
  DateTime? _since;
  final _debouncer = Debouncer();
  final _throttler = Throttler();
  final _duration = const Duration(milliseconds: 300);

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
                    RefreshIndicator(
                      onRefresh: () async {
                        return unsubscribe().whenComplete(() async {
                          clearState();
                          return initialize();
                        });
                      },
                      child: NotificationListener(
                        onNotification: _handleNotification,
                        child: ListView.builder(
                          padding:
                              MediaQuery.maybeOf(context)?.padding.copyWith(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                  ),
                          controller: widget.scrollController == null
                              ? _scrollController
                              : null,
                          scrollDirection: widget.scrollDirection,
                          physics: const ClampingScrollPhysics(),
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
                            if (widget.isDynamicHeight) {
                              return AnimatedSize(
                                key: ValueKey(item.id!),
                                curve: Curves.easeInOutCubic,
                                duration: _duration,
                                child: SizedBox(
                                  height: _heightMap[item.id!],
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    primary: false,
                                    child: ResizeObserver(
                                      onResized: (Size? oldSize, Size newSize) {
                                        if (_heightMap[item.id!] !=
                                            newSize.height) {
                                          _debouncer.debounce(
                                            duration: _duration,
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
                            } else {
                              return Container(
                                key: ValueKey(item.id!),
                                child: widget.itemBuilder(context, item),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    AnimatedSize(
                      curve: Curves.easeInOutCubic,
                      duration: _duration,
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
    if (oldWidget.ids?.join(',') != widget.ids?.join(',') ||
        oldWidget.authors?.length != widget.authors?.length ||
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
    if (widget.itemSorting != null) {
      return widget.itemSorting!(a, b);
    }
    if (!widget.isAscending) {
      return b.createdAt!.compareTo(a.createdAt!);
    } else {
      return a.createdAt!.compareTo(b.createdAt!);
    }
  }

  void subscribe() {
    int hasMore = 0;
    final filter = NostrFilter(
      kinds: widget.kinds,
      authors: widget.authors,
      ids: widget.ids,
      limit: !widget.disableLimit ? _limitRequest : null,
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
              _since ??= DateTime.now();
              _initialized = true;
            });
          }
        }
        _debouncer.debounce(
          duration: _duration,
          onDebounce: () {
            if (mounted) {
              setState(() {
                _loading = false;
                _hasMore = widget.disableLimit
                    ? false
                    : hasMore >= (_limitRequest / 2);
                _items.sort(sorting);
                _items = _items.take(_limitDisplay).toList();
              });
            }
            if (_hasMore) {
              _fetchMoreItems();
            }
          },
        );
        _loading = false;
        _hasMore = widget.disableLimit ? false : hasMore >= (_limitRequest / 2);
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _hasMore = widget.disableLimit ? false : hasMore >= _limitRequest;
          });
        }
      },
    );

    _newEventListener = _newEventStream!.stream.listen(
      (event) async {
        if (event.createdAt == null) return;
        final dataEvent = widget.itemMapper != null
            ? await widget.itemMapper!(DataEvent.fromEvent(event))
            : DataEvent.fromEvent(event);
        if (_allItems.contains(dataEvent)) return;
        _allItems.add(dataEvent);
        if (_since == null || _since!.compareTo(dataEvent.createdAt!) >= 0) {
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
        duration: _duration, curve: Curves.easeInOutCubic);
  }

  void clearState() {
    setState(() {
      _heightMap = {};
      _since = null;
      _loading = true;
      _initialized = false;
      _hasMore = false;
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
    if (!_initialized) {
      if (mounted) {
        setState(() {
          _items.sort(sorting);
          _since ??= DateTime.now();
          _initialized = true;
        });
      }
    } else {
      setState(() {
        _items.sort(sorting);
        _items = _items.take(_limitDisplay).toList();
      });
    }
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

  void fetchFromLastEvent() {
    _loading = true;
    bool triggered = false;
    DateTime? until;
    DateTime? since;
    if (!widget.isAscending) {
      until = _items.last.createdAt;
    }
    int itemIndex = _items.indexOf(_items.last);
    List<DataEvent> tempItems = [];
    NostrFilter filter = NostrFilter(
      until: until,
      since: since,
      limit: _limitRequest,
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
        if (!triggered) {
          triggered = true;
          _loading = false;
        }
        if (mounted) {
          setState(() {
            _hasMore =
                widget.disableLimit ? false : hasMore >= (_limitRequest / 2);
          });
        }
      },
      onEnd: () {
        setState(() {
          _hasMore = widget.disableLimit ? false : hasMore >= _limitRequest;
        });
      },
    );
    _initEventListener = _initEventStream!.stream.listen(
      (event) async {
        hasMore += 1;
        final dataEvent = widget.itemMapper != null
            ? await widget.itemMapper!(DataEvent.fromEvent(event))
            : DataEvent.fromEvent(event);
        if (!_allItems.contains(dataEvent)) {
          _allItems.add(dataEvent);
        }
        if (!filterEvent(dataEvent)) return;
        if (!triggered) {
          triggered = true;
          setState(() {
            _hasMore =
                widget.disableLimit ? false : hasMore >= (_limitRequest / 2);
            _loading = false;
          });
        }
        if (!_items.contains(dataEvent)) {
          tempItems.add(dataEvent);
        }
        _debouncer.debounce(
          duration: _duration,
          onDebounce: () {
            tempItems.sort(sorting);
            _items = _items.take(itemIndex + 1).toList();
            if (mounted) {
              setState(() {
                _items.insertAll(itemIndex + 1, tempItems.take(_limitDisplay));
              });
            }
          },
        );
      },
    );
  }

  void _fetchMoreItems() async {
    if (_initialized != true || _loading == true) return;
    fetchFromLastEvent();
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
            _fetchMoreItems();
          });
      return true;
    }
    return false;
  }
}
