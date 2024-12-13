import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wherostr_social/models/pow_filter.dart';

class FeedFilters {
  bool followingSelected;
  bool articlesSelected;
  bool liveActivitiesSelected;
  bool repliesSelected;
  bool repostsSelected;
  List<String> selectedFollowingSets;
  List<String> selectedFollowingHashtags;

  FeedFilters({
    this.followingSelected = true,
    this.articlesSelected = true,
    this.liveActivitiesSelected = true,
    this.repliesSelected = false,
    this.repostsSelected = true,
    this.selectedFollowingSets = const [],
    this.selectedFollowingHashtags = const [],
  });

  factory FeedFilters.fromJson(Map<String, dynamic> json) {
    return FeedFilters(
      followingSelected: json['followingSelected'],
      articlesSelected: json['articlesSelected'],
      liveActivitiesSelected: json['liveActivitiesSelected'],
      repliesSelected: json['repliesSelected'],
      repostsSelected: json['repostsSelected'],
      selectedFollowingSets: List<String>.from(json['selectedFollowingSets']),
      selectedFollowingHashtags:
          List<String>.from(json['selectedFollowingHashtags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followingSelected': followingSelected,
      'articlesSelected': articlesSelected,
      'liveActivitiesSelected': liveActivitiesSelected,
      'repliesSelected': repliesSelected,
      'repostsSelected': repostsSelected,
      'selectedFollowingSets': selectedFollowingSets,
      'selectedFollowingHashtags': selectedFollowingHashtags,
    };
  }
}

class AppFeedProvider with ChangeNotifier {
  final _storage = GetStorage('app');

  AppFeedProvider() {
    _init();
  }
  FeedFilters _feedFilters = FeedFilters();
  FeedFilters get feedFilters => _feedFilters;
  PoWfilter _powPostFilter = PoWfilter(enabled: false, value: 16);
  PoWfilter _powCommentFilter = PoWfilter(enabled: false, value: 8);
  PoWfilter get powPostFilter => _powPostFilter;
  PoWfilter get powCommentFilter => _powCommentFilter;

  Future<void> _init() async {
    if (_storage.hasData('app_feed_filters')) {
      _feedFilters =
          FeedFilters.fromJson(jsonDecode(_storage.read('app_feed_filters')));
    }
    try {
      if (_storage.hasData('app_pow_post')) {
        _powPostFilter = PoWfilter.fromString(_storage.read('app_pow_post'));
      }
      if (_storage.hasData('app_pow_comment')) {
        _powCommentFilter =
            PoWfilter.fromString(_storage.read('app_pow_comment'));
      }
    } catch (err) {
      print(err);
    }
  }

  Future<void> setFeedFilters(FeedFilters feedFilters) async {
    await _storage.write('app_feed_filters', jsonEncode(feedFilters.toJson()));
    _feedFilters = feedFilters;
    notifyListeners();
  }

  Future<void> setPoWPostFilter(PoWfilter? value) async {
    if (value == null) {
      return _storage.remove('app_pow_post');
    }
    await _storage.write('app_pow_post', value.toString());
    _powPostFilter = value;
    notifyListeners();
  }

  Future<void> setPoWCommentFilter(PoWfilter? value) async {
    if (value == null) {
      return _storage.remove('app_pow_comment');
    }
    await _storage.write('app_pow_comment', value.toString());
    _powCommentFilter = value;
    notifyListeners();
  }
}
