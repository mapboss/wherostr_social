import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AppNotificationProvider with ChangeNotifier {
  AppNotificationProvider() {
    _init();
  }

  int? _messagingLastSeen;
  int _notificationLastSeen = DateTime.now().millisecondsSinceEpoch;
  bool _notificationOn = false;
  bool _notificationSound = false;
  bool _notificationVibrate = false;

  bool _notificationDirectMessages = true;
  bool _notificationReactions = true;
  bool _notificationZaps = true;
  bool _notificationMentions = true;
  bool _notificationReposts = true;

  int? get messagingLastSeen => _messagingLastSeen;
  int get notificationLastSeen => _notificationLastSeen;
  bool get notificationOn => _notificationOn;
  bool get notificationSound => _notificationSound;
  bool get notificationVibrate => _notificationVibrate;
  bool get notificationDirectMessages => _notificationDirectMessages;
  bool get notificationReactions => _notificationReactions;
  bool get notificationZaps => _notificationZaps;
  bool get notificationMentions => _notificationMentions;
  bool get notificationReposts => _notificationReposts;

  Future<void> _init() async {
    final storage = GetStorage('app');
    _messagingLastSeen = storage.read<int?>('app_messaging_last_seen');
    _notificationLastSeen = storage.read<int>('app_notification_last_seen') ??
        DateTime.now().millisecondsSinceEpoch;
    _notificationOn = storage.read('app_notification_on') ?? false;
    _notificationSound = storage.read('app_notification_sound') ?? false;
    _notificationVibrate = storage.read('app_notification_vibrate') ?? false;
    _notificationDirectMessages =
        storage.read('app_notification_direct_messages') ?? true;
    _notificationMentions = storage.read('app_notification_mentions') ?? true;
    _notificationZaps = storage.read('app_notification_zaps') ?? true;
    _notificationReactions = storage.read('app_notification_reactions') ?? true;
    _notificationReposts = storage.read('app_notification_reposts') ?? true;
  }

  Future<void> setMessagingLastSeen(int value) async {
    final storage = GetStorage('app');
    await storage.write('app_messaging_last_seen', value);
    _messagingLastSeen = value;
    notifyListeners();
  }

  Future<void> setNotificationLastSeen(int value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_last_seen', value);
    _notificationLastSeen = value;
    notifyListeners();
  }

  Future<void> setNotificationOn(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_on', value);
    _notificationOn = value;
    notifyListeners();
  }

  Future<void> setNotificationSound(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_sound', value);
    _notificationSound = value;
    notifyListeners();
  }

  Future<void> setNotificationVibrate(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_vibrate', value);
    _notificationVibrate = value;
    notifyListeners();
  }

  Future<void> setNotificationDirectMessages(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_direct_messages', value);
    _notificationDirectMessages = value;
    notifyListeners();
  }

  Future<void> setNotificationMentions(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_mentions', value);
    _notificationMentions = value;
    notifyListeners();
  }

  Future<void> setNotificationZaps(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_zaps', value);
    _notificationZaps = value;
    notifyListeners();
  }

  Future<void> setNotificationReactions(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_reactions', value);
    _notificationReactions = value;
    notifyListeners();
  }

  Future<void> setNotificationReposts(bool value) async {
    final storage = GetStorage('app');
    await storage.write('app_notification_reposts', value);
    _notificationReposts = value;
    notifyListeners();
  }
}
