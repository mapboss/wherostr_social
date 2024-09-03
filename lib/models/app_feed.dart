import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wherostr_social/models/feed_menu_item.dart';

final followingMenuItem = FeedMenuItem(
    id: 'following', name: 'Following', type: 'default', value: ['following']);
final globalMenuItem = FeedMenuItem(
    id: 'global', name: 'Global', type: 'default', value: ['global']);

class AppFeedProvider with ChangeNotifier {
  AppFeedProvider() {
    _init();
  }

  FeedMenuItem _selectedItem = followingMenuItem;

  FeedMenuItem get selectedItem => _selectedItem;

  Future<void> _init() async {
    var storage = GetStorage('app');
    if (storage.hasData('app_feed')) {
      _selectedItem = FeedMenuItem.fromString(storage.read('app_feed'));
    } else {
      _selectedItem = followingMenuItem;
    }
  }

  Future<void> setSelectedItem(FeedMenuItem item) async {
    var storage = GetStorage('app');
    await storage.write('app_feed', item.toString());
    _selectedItem = item;
    notifyListeners();
  }
}
