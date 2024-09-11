import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wherostr_social/models/feed_menu_item.dart';
import 'package:wherostr_social/models/pow_filter.dart';

final followingMenuItem = FeedMenuItem(
    id: 'following', name: 'Following', type: 'default', value: ['following']);
final globalMenuItem = FeedMenuItem(
    id: 'global', name: 'Global', type: 'default', value: ['global']);

class AppFeedProvider with ChangeNotifier {
  final _storage = GetStorage('app');

  AppFeedProvider() {
    _init();
  }

  PoWfilter _powPostFilter = PoWfilter(enabled: false, value: 16);
  PoWfilter _powCommentFilter = PoWfilter(enabled: false, value: 8);
  PoWfilter get powPostFilter => _powPostFilter;
  PoWfilter get powCommentFilter => _powCommentFilter;

  FeedMenuItem _selectedItem = followingMenuItem;

  FeedMenuItem get selectedItem => _selectedItem;

  Future<void> _init() async {
    if (_storage.hasData('app_feed')) {
      _selectedItem = FeedMenuItem.fromString(_storage.read('app_feed'));
    } else {
      _selectedItem = followingMenuItem;
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

  Future<void> setSelectedItem(FeedMenuItem item) async {
    await _storage.write('app_feed', item.toString());
    _selectedItem = item;
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
