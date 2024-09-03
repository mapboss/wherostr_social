import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wherostr_social/models/feed_filter_menu_item.dart';

final followingMenuItem = FeedFilterMenuItem(
    id: 'following', name: 'Following', type: 'default', value: ['following']);
final globalMenuItem = FeedFilterMenuItem(
    id: 'global', name: 'Global', type: 'default', value: ['global']);

class AppFeedFilterProvider with ChangeNotifier {
  AppFeedFilterProvider() {
    _init();
  }

  FeedFilterMenuItem _feed = followingMenuItem;

  FeedFilterMenuItem get feed => _feed;

  Future<void> _init() async {
    var storage = GetStorage('app');
    if (storage.hasData('app_feed')) {
      _feed = storage.read('app_feed');
    } else {
      _feed = followingMenuItem;
    }
  }

  Future<void> setFeedFilter(FeedFilterMenuItem item) async {
    var storage = GetStorage('app');
    await storage.write('app_feed', item);
    _feed = item;
    notifyListeners();
  }
}
