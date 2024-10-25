import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wherostr_social/models/app_settings.dart';
import 'package:wherostr_social/models/app_theme.dart';
import 'package:wherostr_social/models/data_event.dart';
import 'package:wherostr_social/widgets/post_item.dart';

DataEvent previewEvent = DataEvent.fromJson(const {
  "created_at": 1231006505,
  "kind": 1,
  "pubkey": "d67e88b9279a53626c9f716c976718ad245c45ffe2463119424d19b34bf845ac",
  "content":
      "Welcome to Wherostr!\nDiscover a new way to connect with Wherostr, a cutting-edge decentralized geo-social app built on the Nostr protocol.",
});

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    MyThemeExtension themeExtension = themeData.extension<MyThemeExtension>()!;
    final appTheme = context.watch<AppThemeProvider>();
    final isDarkMode = appTheme.themeMode == ThemeMode.dark;
    final appSettings = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SingleChildScrollView(
        child: Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Theme',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) => appTheme
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Content display',
                  style: TextStyle(color: themeExtension.textDimColor),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Collapse long posts'),
                trailing: Switch(
                  value: appSettings.collapseLongPost,
                  onChanged: (value) => appSettings.setCollapseLongPost(value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Font size'),
                trailing: TextButton(
                  onPressed: () => appSettings.setContentFontSizeDelta(0),
                  child: Text('Default'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: Slider(
                    value: appSettings.contentFontSizeDelta,
                    min: -4,
                    max: 16,
                    divisions: 10,
                    inactiveColor: themeData.colorScheme.surfaceDim,
                    onChanged: (value) =>
                        appSettings.setContentFontSizeDelta(value),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeData.colorScheme.primary,
                      ),
                    ),
                    child: PostItem(
                      event: previewEvent,
                      enableMenu: false,
                      enableTap: false,
                      enableActionBar: false,
                      enableLocation: false,
                      enableProofOfWork: false,
                      enablePreview: false,
                      enableMedia: false,
                      enableElementTap: false,
                      enableShowProfileAction: false,
                    ),
                  ),
                ),
              ),
              // const Divider(),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              //   child: Text(
              //     'Language',
              //     style: TextStyle(color: themeExtension.textDimColor),
              //   ),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.key),
              //   title: const Text('Language'),
              //   trailing: const Icon(Icons.arrow_forward_ios),
              //   onTap: () {
              //     var appLocale = context.read<AppLocaleProvider>();
              //     if (appLocale.locale == const Locale('th')) {
              //       appLocale.setLocale(const Locale('en'));
              //     } else {
              //       appLocale.setLocale(const Locale('th'));
              //     }
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
