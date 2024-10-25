import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_notification.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  @override
  Widget build(BuildContext context) {
    final appNotifications = context.watch<AppNotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        child: Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_on),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: appNotifications.notificationOn,
                  onChanged: (value) =>
                      appNotifications.setNotificationOn(value),
                ),
              ),
              Divider(),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.notifications_active),
                title: const Text('Sound'),
                trailing: Switch(
                  value: appNotifications.notificationSound,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) => appNotifications.setNotificationSound(value),
                ),
              ),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.vibration),
                title: const Text('Vibrate'),
                trailing: Switch(
                  value: appNotifications.notificationVibrate,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) =>
                          appNotifications.setNotificationVibrate(value),
                ),
              ),
              Divider(),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.mail),
                title: const Text('Direct Messages'),
                trailing: Switch(
                  value: appNotifications.notificationDirectMessages,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) =>
                          appNotifications.setNotificationDirectMessages(value),
                ),
              ),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.settings),
                title: const Text('Mentions'),
                trailing: Switch(
                  value: appNotifications.notificationMentions,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) =>
                          appNotifications.setNotificationMentions(value),
                ),
              ),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.electric_bolt),
                title: const Text('Zaps'),
                trailing: Switch(
                  value: appNotifications.notificationZaps,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) => appNotifications.setNotificationZaps(value),
                ),
              ),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.thumb_up),
                title: const Text('Reactions'),
                trailing: Switch(
                  value: appNotifications.notificationReactions,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) =>
                          appNotifications.setNotificationReactions(value),
                ),
              ),
              ListTile(
                enabled: appNotifications.notificationOn,
                leading: const Icon(Icons.repeat),
                title: const Text('Reposts'),
                trailing: Switch(
                  value: appNotifications.notificationReposts,
                  onChanged: !appNotifications.notificationOn
                      ? null
                      : (value) =>
                          appNotifications.setNotificationReposts(value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
